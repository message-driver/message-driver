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
        def subscriptions
          adapter.subscriptions_for(name)
        end

        def handle_message_count
          message_queue.size
        end

        def handle_pop_message(ctx, options = {})
          _fetch_message(ctx, options)
        end

        def handle_subscribe(options = {}, &consumer)
          subscription = Subscription.new(adapter, self, consumer, options)
          adapter.add_subscription_for(name, subscription)
          _deliver_messages
          subscription
        end

        def handle_publish(body, headers = {}, properties = {})
          raw_body = body
          b, h, p = middleware.on_publish(body, headers, properties)
          msg = Message.new(nil, self, b, h, p, raw_body)
          message_queue << msg
          _deliver_messages
        end

        private

        def next_subscription
          adapter.next_subscription_for(name)
        end

        def _fetch_message(ctx, _options = {})
          message = message_queue.shift
          if message.nil?
            nil
          else
            raw_body = message.body
            b, h, p = middleware.on_consume(message.body, message.headers, message.properties)
            Message.new(ctx, self, b, h, p, raw_body)
          end
        end

        def _deliver_messages
          unless subscriptions.empty?
            until (msg = _fetch_message(current_adapter_context)).nil?
              sub = next_subscription # this actually cycles through the subscriptions
              sub.deliver_message(msg)
            end
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
      alias handle_create_destination create_destination

      class InMemoryContext < ContextBase
        extend Forwardable

        def_delegators :adapter, :handle_create_destination

        def handle_publish(destination, body, headers = {}, properties = {})
          destination.handle_publish(body, headers, properties)
        end

        def handle_pop_message(destination, options = {})
          destination.handle_pop_message(self, options)
        end

        def handle_subscribe(destination, options = {}, &consumer)
          destination.handle_subscribe(options, &consumer)
        end

        def handle_message_count(destination)
          destination.handle_message_count
        end

        def handle_consumer_count(destination)
          adapter.consumer_count_for(destination.name)
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

      def subscriptions_for(name)
        @subscriptions[name]
      end

      def next_subscription_for(name)
        unless (subs = @subscriptions[name]).empty?
          sub = subs.shift
          subs.push sub
          sub
        end
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
