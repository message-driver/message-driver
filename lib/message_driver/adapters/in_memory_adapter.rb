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
        def initialize(adapter, name, dest_options, message_props, message_store)
          super(adapter, name, dest_options, message_props)
          @message_store = message_store
        end
        def message_count
          @message_store[@name].size
        end
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
        message_store.clear
      end

      def create_destination(name, dest_options={}, message_props={})
        Destination.new(self, name, dest_options, message_props, message_store)
      end

      def reset_after_tests
        message_store.each do |destination, message_array|
          message_array.replace([])
        end
      end

      private

      def message_store
        @message_store ||= Hash.new { |h,k| h[k] = [] }
      end
    end
  end
end
