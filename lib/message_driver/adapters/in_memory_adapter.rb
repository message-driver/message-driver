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

        def consumer
          @consumers[name]
        end

        def message_count
          message_queue.size
        end

        def pop_message(options={})
          message_queue.shift
        end

        def publish(body, headers={}, properties={})
          msg = Message.new(body, headers, properties)
          if consumer.nil?
            message_queue << msg
          else
            consumer.call(msg)
          end
        end

        private
        def after_initialize
          @message_store = dest_options.delete(:message_store)
          @consumers = dest_options.delete(:consumers)
        end

        def message_queue
          @message_store[name]
        end
      end

      def initialize(config={})
        @destinations = {}
        @message_store = Hash.new { |h,k| h[k] = [] }
        @consumers = Hash.new
      end

      def publish(destination, body, headers={}, properties={})
        destination(destination).publish(body, headers, properties)
      end

      def pop_message(destination, options={})
        destination(destination).pop_message(options)
      end

      def stop
        reset_after_tests
      end

      def create_destination(name, dest_options={}, message_props={})
        destination = Destination.new(self, name, dest_options.merge(message_store: @message_store, consumers: @consumers), message_props)
        @destinations[name] = destination
      end

      def subscribe(destination_name, &consumer)
        destination = destination(destination_name)
        @consumers[destination_name] = consumer
        until (msg = destination.pop_message).nil?
          yield msg
        end
      end

      def reset_after_tests
        @message_store.keys.each do |k|
          @message_store[k] = []
        end
        @consumers.clear
      end

      private

      def destination(destination_name)
        destination = @destinations[destination_name]
        raise MessageDriver::NoSuchDestinationError, "destination #{destination_name} couldn't be found" if destination.nil?
        destination
      end

      def consumer(destination_name)
        @consumers[destination_name]
      end
    end
  end
end
