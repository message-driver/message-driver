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
          @adapter.current_context.with_channel do |ch|
            queue = ch.queue(@name, @dest_options)
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
      end

      class ExchangeDestination < Destination
        def pop_message(destination, options={})
          raise "You can't pop a message off an exchange"
        end

        def after_initialize
          @adapter.current_context.with_channel do |ch|
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
        current_context.with_channel do |ch|
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
        attr_reader :connection, :is_transactional

        def initialize(connection)
          @connection = connection
          @channel = connection.create_channel
          @transaction_depth = 0
          @is_transactional = false
        end

        def with_transaction(&block)
          if !is_transactional
            @channel.tx_select
            @is_transactional = true
          end

          begin
            @transaction_depth += 1
            yield
            @channel.tx_commit if @transaction_depth == 1
          rescue
            @channel.tx_rollback if @transaction_depth == 1
            raise
          ensure
            @transaction_depth -= 1
          end
        end

        def with_channel
          result = yield @channel
          if is_transactional && @transaction_depth < 1
            @channel.tx_commit
          end
          result
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
