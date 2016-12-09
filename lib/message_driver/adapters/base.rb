module MessageDriver
  module Adapters
    class Base
      include Logging

      attr_reader :broker

      def contexts
        @contexts ||= []
      end

      def initialize(_broker, _configuration)
        raise 'Must be implemented in subclass'
      end

      def new_context
        ctx = build_context
        contexts << ctx
        ctx
      end

      def build_context
        raise 'Must be implemented in subclass'
      end

      def reset_after_tests
        # does nothing, can be overridden by adapters that want to support testing scenarios
      end

      def stop
        if @contexts
          ctxs = @contexts
          @contexts = []
          ctxs.each(&:invalidate)
        end
      end
    end

    class ContextBase
      include Logging

      attr_reader :adapter
      attr_accessor :valid

      def initialize(adapter)
        @adapter = adapter
        @valid = true
      end

      def publish(destination, body, headers = {}, properties = {})
        handle_publish(destination, body, headers, properties)
      end

      def pop_message(destination, options = {})
        handle_pop_message(destination, options)
      end

      def subscribe(destination, options = {}, &consumer)
        handle_subscribe(destination, options, &consumer)
      end

      def create_destination(name, dest_options = {}, message_props = {})
        handle_create_destination(name, dest_options, message_props)
      end

      def ack_message(message, options = {})
        handle_ack_message(message, options)
      end

      def nack_message(message, options = {})
        handle_nack_message(message, options)
      end

      def begin_transaction(options = {})
        handle_begin_transaction(options)
      end

      def commit_transaction(options = {})
        handle_commit_transaction(options)
      end

      def rollback_transaction(options = {})
        handle_rollback_transaction(options)
      end

      def message_count(destination)
        handle_message_count(destination)
      end

      def consumer_count(destination)
        handle_consumer_count(destination)
      end

      def in_transaction?
        if supports_transactions?
          raise 'must be implemented in subclass'
        else
          raise "#in_transaction? not supported by #{adapter.class}"
        end
      end

      def valid?
        @valid
      end

      def invalidate
        @valid = false
      end

      def supports_transactions?
        false
      end

      def supports_client_acks?
        false
      end

      def supports_subscriptions?
        false
      end

      def handle_create_destination(_name, _dest_options = {}, _message_props = {})
        raise 'Must be implemented in subclass'
      end

      def handle_publish(_destination, _body, _headers = {}, _properties = {})
        raise 'Must be implemented in subclass'
      end

      def handle_pop_message(_destination, _options = {})
        raise 'Must be implemented in subclass'
      end

      def handle_subscribe(_destination, _options = {}, &_consumer)
        if supports_subscriptions?
          raise 'Must be implemented in subclass'
        else
          raise "#subscribe is not supported by #{adapter.class}"
        end
      end

      def handle_ack_message(_message, _options = {})
        if supports_client_acks?
          raise 'Must be implemented in subclass'
        else
          raise "#ack_message is not supported by #{adapter.class}"
        end
      end

      def handle_nack_message(_message, _options = {})
        if supports_client_acks?
          raise 'Must be implemented in subclass'
        else
          raise "#nack_message is not supported by #{adapter.class}"
        end
      end

      def handle_begin_transaction(_options = {})
        if supports_transactions?
          raise 'Must be implemented in subclass'
        else
          raise "transactions are not supported by #{adapter.class}"
        end
      end

      def handle_commit_transaction(_options = {})
        if supports_transactions?
          raise 'Must be implemented in subclass'
        else
          raise "transactions are not supported by #{adapter.class}"
        end
      end

      def handle_rollback_transaction(_options = {})
        if supports_transactions?
          raise 'Must be implemented in subclass'
        else
          raise "transactions are not supported by #{adapter.class}"
        end
      end

      def handle_message_count(destination)
        raise "#message_count is not supported by #{destination.class}"
      end

      def handle_consumer_count(destination)
        raise "#consumer_count is not supported by #{destination.class}"
      end
    end
  end
end
