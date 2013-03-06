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
        def send_message(body, headers={}, properties={})
          props = @message_props.merge(properties)
          props[:headers] = headers if headers
          @adapter.send_message(body, exchange_name, routing_key(properties), props)
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
          adapter.connection.with_channel do |ch|
            ch.queue(@name, @dest_options)
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
      end

      attr_reader :connection

      def initialize(config)
        validate_bunny_version

        @connection = Bunny.new(config)
        @connection.start
      end

      def send_message(body, exchange, routing_key, properties)
        @connection.with_channel do |ch|
          ch.basic_publish(body, exchange, routing_key, properties)
        end
      end

      def pop_message(destination, options={})
        result = nil
        @connection.with_channel do |ch|
          queue = ch.queue(destination, passive: true)

          message = queue.pop
          if message.nil? || message[0].nil?
            nil
          else
            result = Message.new(*message)
          end
        end
        result
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

      def stop
        @connection.close
      end

      private

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
