require 'forwardable'

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

      def new_context
        InMemoryContext.new(self)
      end

      def create_destination(name, dest_options={}, message_props={})
        destination = Destination.new(self, name, dest_options, message_props)
        @destinations[name] = destination
      end

      class InMemoryContext < ContextBase
        extend Forwardable

        def_delegators :adapter, :create_destination

        def publish(destination, body, headers={}, properties={})
          destination.publish(body, headers, properties)
        end

        def pop_message(destination, options={})
          destination.pop_message(options)
        end

        def subscribe(destination, options={}, &consumer)
          destination.subscribe(&consumer)
        end

        def supports_subscriptions?
          true
        end
      end

      def stop
        super
        reset_after_tests
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
    end
  end
end
