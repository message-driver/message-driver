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
          super(payload, properties[:headers], properties)
        end
      end

      class Destination < MessageDriver::Destination::Base
      end

      class QueueDestination < Destination
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

      def send_message(destination, body, headers={}, properties={})
        @connection.with_channel do |ch|
          queue = ch.queue(destination, passive: true)

          options = {}.merge(properties)
          options[:headers] = headers unless headers.empty?

          queue.publish(body, options)
        end
      end

      def pop_message(destination, options={})
        result = nil
        @connection.with_channel do |ch|
          queue = ch.queue(destination, passive: true)

          message = queue.pop
          result = Message.new(*message)
        end
        result
      end

      def create_destination(name, dest_options={}, message_props={})
        case dest_options[:type]
        when :exchange
          ExchangeDestination.new(self, name, dest_options, message_props)
        when :queue, nil
          QueueDestination.new(self, name, dest_options, message_props)
        else
          raise "invalid destination type #{dest_options[:type]}"
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
