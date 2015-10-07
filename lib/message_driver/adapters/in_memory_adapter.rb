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
          adapter.remove_subscription_for(destination.name, self)
        end

        def deliver_message(message)
          consumer.call(message)
        rescue => e
          unless options[:error_handler].nil?
            options[:error_handler].call(e, message)
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

        def consumer_count
          adapter.consumer_count_for(name)
        end

        def pop_message(_options = {})
          message = message_queue.shift
          if message.nil?
            nil
          else
            raw_body = message.body
            b, h, p = middleware.on_consume(message.body, message.headers, message.properties)
            Message.new(nil, b, h, p, raw_body)
          end
        end

        def subscribe(options = {}, &consumer)
          subscription = Subscription.new(adapter, self, consumer, options)
          adapter.add_subscription_for(name, subscription)
          deliver_messages(subscription)
          subscription
        end

        def publish(body, headers = {}, properties = {})
          raw_body = body
          b, h, p = middleware.on_publish(body, headers, properties)
          msg = Message.new(nil, b, h, p, raw_body)
          message_queue << msg
          deliver_messages(subscription) if subscription
        end

        private

        def deliver_messages(sub)
          until (msg = pop_message).nil?
            sub.deliver_message(msg)
          end
        end

        def message_queue
          adapter.message_queue_for(name)
        end
      end

      def initialize(broker, _config = {})
        @broker = broker
        @destinations = {}
        begin
          require 'thread_safe'
          @message_store = ThreadSafe::Cache.new { |h, k| h[k] = [] }
          @subscriptions = ThreadSafe::Cache.new { |h, k| h[k] = [] }
        rescue LoadError
          @message_store = Hash.new { |h, k| h[k] = [] }
          @subscriptions = Hash.new { |h, k| h[k] = [] }
        end
      end

      def build_context
        InMemoryContext.new(self)
      end

      def create_destination(name, dest_options = {}, message_props = {})
        destination = Destination.new(self, name, dest_options, message_props)
        @destinations[name] = destination
      end

      class InMemoryContext < ContextBase
        extend Forwardable

        def_delegators :adapter, :create_destination

        def publish(destination, body, headers = {}, properties = {})
          destination.publish(body, headers, properties)
        end

        def pop_message(destination, options = {})
          destination.pop_message(options)
        end

        def subscribe(destination, options = {}, &consumer)
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
        sub = @subscriptions[name].shift
        @subscriptions[name].push sub
        sub
      end

      def add_subscription_for(name, subscription)
        @subscriptions[name].push subscription
      end

      def remove_subscription_for(name, subscription)
        @subscriptions[name].delete(subscription)
      end

      def consumer_count_for(name)
        @subscriptions[name].size
      end
    end
  end
end
