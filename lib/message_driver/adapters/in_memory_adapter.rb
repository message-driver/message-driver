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
          adapter.remove_subscription_for(destination.name)
        end

        def deliver_message(message)
          begin
            consumer.call(message)
          rescue => e
            unless options[:error_handler].nil?
              options[:error_handler].call(e, message)
            end
          end
        end
      end

      class Destination < MessageDriver::Destination::Base

        def subscription
          adapter.subscription_for(name)
        end

        def message_count
          message_queue.size
        end

        def pop_message(options={})
          message_queue.shift
        end

        def subscribe(options={}, &consumer)
          subscription = Subscription.new(adapter, self, consumer, options)
          adapter.set_subscription_for(name, subscription)
          until (msg = pop_message).nil?
            subscription.deliver_message(msg)
          end
          subscription
        end

        def publish(body, headers={}, properties={})
          msg = Message.new(nil, body, headers, properties)
          sub = subscription
          if sub.nil?
            message_queue << msg
          else
            sub.deliver_message(msg)
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
        @subscriptions = Hash.new
      end

      def build_context
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
          destination.subscribe(options, &consumer)
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
        @subscriptions.clear
      end

      def message_queue_for(name)
        @message_store[name]
      end

      def subscription_for(name)
        @subscriptions[name]
      end

      def set_subscription_for(name, subscription)
        @subscriptions[name] = subscription
      end

      def remove_subscription_for(name)
        @subscriptions.delete(name)
      end
    end
  end
end
