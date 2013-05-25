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

      class Subscription < MessageDriver::Subscription::Base
        def unsubscribe
          adapter.remove_consumer_for(destination.name)
        end
      end

      class Destination < MessageDriver::Destination::Base

        def consumer
          adapter.consumer_for(name)
        end

        def message_count
          message_queue.size
        end

        def pop_message(options={})
          message_queue.shift
        end

        def subscribe(&consumer)
          adapter.set_consumer_for(name, &consumer)
          until (msg = pop_message).nil?
            yield msg
          end
          Subscription.new(adapter, self, consumer)
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
        def message_queue
          adapter.message_queue_for(name)
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
        destination = Destination.new(self, name, dest_options, message_props)
        @destinations[name] = destination
      end

      def reset_after_tests
        @message_store.keys.each do |k|
          @message_store[k] = []
        end
        @consumers.clear
      end

      def message_queue_for(name)
        @message_store[name]
      end

      def consumer_for(name)
        @consumers[name]
      end

      def set_consumer_for(name, &consumer)
        @consumers[name] = consumer
      end

      def remove_consumer_for(name)
        @consumers.delete(name)
      end

      private

      def destination(destination_name)
        destination = @destinations[destination_name]
        raise MessageDriver::NoSuchDestinationError, "destination #{destination_name} couldn't be found" if destination.nil?
        destination
      end
    end
  end
end
