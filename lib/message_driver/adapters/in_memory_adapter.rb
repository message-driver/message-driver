module MessageDriver
  class Broker
    def self.in_memory_adapter
      MessageDriver::Adapters::InMemoryAdapter
    end
  end

  module Adapters
    class InMemoryAdapter < Base
      def initialize(config={})
        #does nothing
      end

      def send_message(destination, body, headers={}, properties={})
        message_store[destination] << Message.new(body, headers, properties)
      end

      def pop_message(destination, options={})
        message_store[destination].shift
      end

      def stop
        @message_stop = nil
      end

      def create_destination(destination_name, options={})
        #doesn't need to do anything
      end

      private

      def message_store
        @message_store ||= Hash.new { |h,k| h[k] = [] }
      end

      class Message < MessageDriver::Message::Base

      end
    end
  end
end
