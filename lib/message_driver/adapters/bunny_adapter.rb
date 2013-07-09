require 'bunny'

module MessageDriver
  class Broker
    def bunny_adapter
      MessageDriver::Adapters::BunnyAdapter
    end
  end

  module Adapters
    class BunnyAdapter < Base

      class Message < MessageDriver::Message::Base
        attr_reader :delivery_info

        def initialize(delivery_info, properties, payload)
          super(payload, properties[:headers]||{}, properties)
          @delivery_info = delivery_info
        end
      end

      class Destination < MessageDriver::Destination::Base
        def publish_params(headers, properties)
          props = @message_props.merge(properties)
          props[:headers] = headers if headers
          [exchange_name, routing_key(properties), props]
        end

        def exchange_name
          @name
        end

        def routing_key(properties)
          properties[:routing_key]
        end
      end

      class QueueDestination < Destination
        def after_initialize(adapter_context)
          unless @dest_options[:no_declare]
            adapter_context.with_channel(false) do |ch|
              queue = ch.queue(@name, @dest_options)
              @name = queue.name
              if bindings = @dest_options[:bindings]
                bindings.each do |bnd|
                  raise MessageDriver::Error, "binding #{bnd.inspect} must provide a source!" unless bnd[:source]
                  queue.bind(bnd[:source], bnd[:args]||{})
                end
              end
            end
          else
            raise MessageDriver::Error, "server-named queues must be declared, but you provided :no_declare => true" if @name.empty?
            raise MessageDriver::Error, "queues with bindings must be declared, but you provided :no_declare => true" if @dest_options[:bindings]
          end
        end

        def exchange_name
          ""
        end

        def routing_key(properties)
          @name
        end

        def message_count
          Client.current_adapter_context.with_channel(false) do |ch|
            ch.queue(@name, @dest_options.merge(passive: true)).message_count
          end
        end
      end

      class ExchangeDestination < Destination
        def after_initialize(adapter_context)
          if declare = @dest_options[:declare]
            adapter_context.with_channel(false) do |ch|
              type = declare.delete(:type)
              raise MessageDriver::Error, "you must provide a valid exchange type" unless type
              ch.exchange_declare(@name, type, declare)
            end
          end
          if bindings = @dest_options[:bindings]
            adapter_context.with_channel(false) do |ch|
              bindings.each do |bnd|
                raise MessageDriver::Error, "binding #{bnd.inspect} must provide a source!" unless bnd[:source]
                ch.exchange_bind(bnd[:source], @name, bnd[:args]||{})
              end
            end
          end
        end
      end

      def initialize(config)
        validate_bunny_version

        @connection = Bunny.new(config.merge(automatically_recover: false))
      end

      def connection(ensure_started=true)
        if ensure_started && !@connection.open?
          @connection.start
        end
        @connection
      end

      def stop
        super
        @connection.close if @connection.open?
      end

      def new_context
        BunnyContext.new(self)
      end

      class BunnyContext < ContextBase
        def initialize(adapter)
          super
          @channel = nil
          @is_transactional = false
          @rollback_only = false
          @need_channel_reset = false
          @connection_failed = false
          @in_transaction = false
        end

        def supports_transactions?
          true
        end

        def create_destination(name, dest_options={}, message_props={})
          dest = case type = dest_options.delete(:type)
          when :exchange
            ExchangeDestination.new(self.adapter, name, dest_options, message_props)
          when :queue, nil
            QueueDestination.new(self.adapter, name, dest_options, message_props)
          else
            raise MessageDriver::Error, "invalid destination type #{type}"
          end
          dest.after_initialize(self)
          dest
        end

        def is_transactional?
          @is_transactional
        end

        def in_transaction
          @in_transaction
        end

        def connection_failed?
          @connection_failed
        end

        def begin_transaction(options={})
          raise MessageDriver::TransactionError, "you can't begin another transaction, you are already in one!" if @in_transaction
          unless is_transactional?
            with_channel(false) do |ch|
              ch.tx_select
            end
            @is_transactional = true
          end
          @in_transaction = true
        end

        def commit_transaction
          raise MessageDriver::TransactionError, "you can't finish the transaction unless you already in one!" unless @in_transaction
          begin
            if is_transactional? && !connection_failed? && !@need_channel_reset
              if @rollback_only
                @channel.tx_rollback
              else
                @channel.tx_commit
              end
            end
          ensure
            @rollback_only = false
            @in_transaction = false
          end
        end

        def rollback_transaction
          @rollback_only = true
          commit_transaction
        end

        def publish(destination, body, headers={}, properties={})
          exchange, routing_key, props = *destination.publish_params(headers, properties)
          with_channel(true) do |ch|
            ch.basic_publish(body, exchange, routing_key, props)
          end
        end

        def pop_message(destination, options={})
          raise MessageDriver::Error, "You can't pop a message off an exchange" if destination.is_a? ExchangeDestination

          with_channel(false) do |ch|
            queue = ch.queue(destination.name, passive: true)

            message = queue.pop
            if message.nil? || message[0].nil?
              nil
            else
              Message.new(*message)
            end
          end
        end

        def subscribe(destination, consumer)
          destination.subscribe(&consumer)
        end

        def with_channel(require_commit=true)
          raise MessageDriver::TransactionRollbackOnly if @rollback_only
          raise MessageDriver::Error, "oh nos!" if @connection_failed
          @channel = adapter.connection.create_channel if @channel.nil?
          reset_channel if @need_channel_reset
          begin
            result = yield @channel
            commit_transaction if require_commit && is_transactional? && !in_transaction
            result
          rescue Bunny::ChannelLevelException => e
            @need_channel_reset = true
            @rollback_only = true if is_transactional?
            if e.kind_of? Bunny::NotFound
              raise MessageDriver::QueueNotFound.new
            else
              raise MessageDriver::WrappedError.new
            end
          rescue Bunny::NetworkErrorWrapper, Bunny::NetworkFailure, IOError => e
            @connection_failed = true
            @rollback_only = true if is_transactional?
            raise MessageDriver::ConnectionError.new
          end
        end

        def valid?
          super && !connection_failed?
        end
        alias :need_new_context? :valid?

        private

        def reset_channel
          unless @channel.open?
            @channel.open
            @is_transactional = false
            @rollback_only = true if @in_transaction
          end
          @need_channel_reset = false
        end
      end

      private

      def validate_bunny_version
        required = Gem::Requirement.create('~> 0.9.0.pre7')
        current = Gem::Version.create(Bunny::VERSION)
        unless required.satisfied_by? current
          raise MessageDriver::Error, "bunny 0.9.0.pre7 or later is required for the bunny adapter"
        end
      end
    end
  end
end
