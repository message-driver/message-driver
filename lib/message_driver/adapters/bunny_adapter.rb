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
        def publish(body, headers={}, properties={})
          props = @message_props.merge(properties)
          props[:headers] = headers if headers
          @adapter.publish(body, exchange_name, routing_key(properties), props)
        end

        def exchange_name
          @name
        end

        def routing_key(properties)
          properties[:routing_key]
        end
      end

      class QueueDestination < Destination
        def after_initialize
          unless @dest_options[:no_declare]
            @adapter.current_context.with_channel(false) do |ch|
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
          @adapter.current_context.with_channel(false) do |ch|
            ch.queue(@name, @dest_options.merge(passive: true)).message_count
          end
        end
      end

      class ExchangeDestination < Destination
        def pop_message(destination, options={})
          raise MessageDriver::Error, "You can't pop a message off an exchange"
        end

        def after_initialize
          if declare = @dest_options[:declare]
            @adapter.current_context.with_channel(false) do |ch|
              type = declare.delete(:type)
              raise MessageDriver::Error, "you must provide a valid exchange type" unless type
              ch.exchange_declare(@name, type, declare)
            end
          end
          if bindings = @dest_options[:bindings]
            @adapter.current_context.with_channel(false) do |ch|
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

        @connection = Bunny.new(config.merge(threaded: false))
      end

      def connection(ensure_started=true)
        if ensure_started && !@connection.open?
          @connection.start
        end
        @connection
      end

      def publish(body, exchange, routing_key, properties)
        current_context.with_channel(true) do |ch|
          ch.basic_publish(body, exchange, routing_key, properties)
        end
      end

      def pop_message(destination, options={})
        current_context.with_channel do |ch|
          queue = ch.queue(destination, passive: true)

          message = queue.pop
          if message.nil? || message[0].nil?
            nil
          else
            Message.new(*message)
          end
        end
      end

      def create_destination(name, dest_options={}, message_props={})
        case type = dest_options.delete(:type)
        when :exchange
          ExchangeDestination.new(self, name, dest_options, message_props)
        when :queue, nil
          QueueDestination.new(self, name, dest_options, message_props)
        else
          raise MessageDriver::Error, "invalid destination type #{type}"
        end
      end

      def with_transaction(options={}, &block)
        current_context.with_transaction(&block)
      end

      def stop
        @connection.close if @connection.open?
        @context = nil
      end

      def current_context
        if !@context.nil? && @context.need_new_context?
          @context = nil
        end
        @context ||= ChannelContext.new(connection)
      end

      private

      class ChannelContext
        attr_reader :connection, :transaction_depth

        def initialize(connection)
          @connection = connection
          @channel = connection.create_channel
          @transaction_depth = 0
          @is_transactional = false
          @rollback_only = false
          @need_channel_reset = false
          @connection_failed = false
        end

        def is_transactional?
          @is_transactional
        end

        def connection_failed?
          @connection_failed
        end

        def with_transaction(&block)
          if !is_transactional?
            @channel.tx_select
            @is_transactional = true
          end

          begin
            @transaction_depth += 1
            yield
            commit_transaction
          rescue
            rollback_transaction
            raise
          ensure
            @transaction_depth -= 1
          end
        end

        def with_channel(require_commit=true)
          raise MessageDriver::TransactionRollbackOnly if @rollback_only
          raise MessageDriver::Error, "oh nos!" if @connection_failed
          reset_channel if @need_channel_reset
          begin
            result = yield @channel
            commit_transaction(true) if require_commit
            result
          rescue Bunny::ChannelLevelException => e
            @need_channel_reset = true
            @rollback_only = true if is_transactional?
            if e.kind_of? Bunny::NotFound
              raise MessageDriver::QueueNotFound.new
            else
              raise MessageDriver::WrappedError.new
            end
          rescue Bunny::NetworkErrorWrapper, IOError => e
            @connection_failed = true
            @rollback_only = true if is_transactional?
            raise MessageDriver::ConnectionError.new
          end
        end

        def within_transaction?
          @transaction_depth > 0
        end

        def need_new_context?
          if is_transactional?
            !within_transaction? && connection_failed?
          else
            connection_failed?
          end
        end

        private

        def reset_channel
          unless @channel.open?
            @channel.open
            @is_transactional = false
          end
          @need_channel_reset = false
        end

        def commit_transaction(from_channel=false)
          threshold = from_channel ? 0 : 1
          if is_transactional? && @transaction_depth <= threshold && !connection_failed?
            unless @need_channel_reset
              unless @rollback_only
                @channel.tx_commit
              else
                @channel.tx_rollback
              end
            end
            @rollback_only = false
          end
        end

        def rollback_transaction
          @rollback_only = true
          commit_transaction
        end
      end

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
