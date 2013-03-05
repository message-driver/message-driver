require 'bunny'

module MessageDriver
  class Broker
    def self.bunny_adapter
      MessageDriver::Adapters::BunnyAdapter
    end
  end

  module Adapters
    class BunnyAdapter < Base
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

      private

      def validate_bunny_version
        required = Gem::Requirement.create('~> 0.9.0.pre7')
        current = Gem::Version.create(Bunny::VERSION)
        unless required.satisfied_by? current
          raise "bunny 0.9.0.pre7 or later is required for the bunny adapter"
        end
      end

      class Message < MessageDriver::Message::Base
        attr_reader :delivery_info

        def initialize(delivery_info, properties, payload)
          super(payload, properties[:headers], properties)
        end
      end
    end
  end
end
