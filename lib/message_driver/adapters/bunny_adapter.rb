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
          @adapter.current_context.with_channel(false) do |ch|
            queue = ch.queue(@name, @dest_options)
            @name = queue.name
            if bindings = @dest_options[:bindings]
              bindings.each do |bnd|
                raise "binding #{bnd.inspect} must provide a source!" unless bnd[:source]
                queue.bind(bnd[:source], bnd[:args]||{})
              end
            end
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
          raise "You can't pop a message off an exchange"
        end

        def after_initialize
          @adapter.current_context.with_channel(false) do |ch|
            if declare = @dest_options[:declare]
              type = declare.delete(:type)
              raise MessageDriver::Exception, "you must provide a valid exchange type" unless type
              ch.exchange_declare(@name, type, declare)
            end
            if bindings = @dest_options[:bindings]
              bindings.each do |bnd|
                raise "binding #{bnd.inspect} must provide a source!" unless bnd[:source]
                ch.exchange_bind(bnd[:source], @name, bnd[:args]||{})
              end
            end
          end
        end
      end

      attr_reader :connection

      def initialize(config)
        validate_bunny_version

        @connection = Bunny.new(config)
        @connection.start
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
          raise "invalid destination type #{type}"
        end
      end

      def with_transaction(options={}, &block)
        current_context.with_transaction(&block)
      end

      def stop
        connection.close
      end

      def current_context
        @context ||= ChannelContext.new(connection)
      end

      private

      class ChannelContext
        attr_reader :connection, :is_transactional, :transaction_depth

        def initialize(connection)
          @connection = connection
          @channel = connection.create_channel
          @transaction_depth = 0
          @is_transactional = false
          @rollback_only = false
          @need_reset = false
        end

        def with_transaction(&block)
          if !is_transactional
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
          reset_channel if @need_reset
          begin
            result = yield @channel
            commit_transaction(true) if require_commit
            result
          rescue Bunny::ChannelLevelException => e
            @need_reset = true
            @rollback_only = true if is_transactional
            if e.kind_of? Bunny::NotFound
              raise MessageDriver::QueueNotFound.new(e)
            else
              raise MessageDriver::WrappedException.new(e)
            end
          end
        end

        private

        def reset_channel
          unless @channel.open?
            @channel.open
            @is_transactional = false
          end
          @need_reset = false
        end

        def commit_transaction(from_channel=false)
          threshold = from_channel ? 0 : 1
          if is_transactional && @transaction_depth <= threshold
            unless @need_reset
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
          raise "bunny 0.9.0.pre7 or later is required for the bunny adapter"
        end
      end
    end
  end
end
