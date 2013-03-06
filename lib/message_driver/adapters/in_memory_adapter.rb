module MessageDriver
  class Broker
    def in_memory_adapter
      MessageDriver::Adapters::InMemoryAdapter
    end
  end

  module Adapters
    class InMemoryAdapter < Base

      class Message < MessageDriver::Message::Base

      end

      class Destination < MessageDriver::Destination::Base

      end

      def initialize(config={})
        #does nothing
      end

      def publish(destination, body, headers={}, properties={})
        message_store[destination] << Message.new(body, headers, properties)
      end

      def pop_message(destination, options={})
        message_store[destination].shift
      end

      def stop
        @message_stop = nil
      end

      def create_destination(name, dest_options={}, message_props={})
        Destination.new(self, name, dest_options, message_props)
      end

      private

      def message_store
        @message_store ||= Hash.new { |h,k| h[k] = [] }
      end
    end
  end
end
