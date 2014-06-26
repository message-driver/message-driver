module MessageDriver
  module Adapters
    class Base
      include Logging

      attr_reader :broker

      def contexts
        @contexts ||= []
      end

      def initialize(broker, configuration)
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
        #does nothing, can be overridden by adapters that want to support testing scenarios
      end

      def stop
        if @contexts
          ctxs = @contexts
          @contexts = []
          ctxs.each { |ctx| ctx.invalidate }
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

      def publish(destination, body, headers={}, properties={})
        raise 'Must be implemented in subclass'
      end

      def pop_message(destination, options={})
        raise 'Must be implemented in subclass'
      end

      def subscribe(destination, options={}, &consumer)
        raise "#subscribe is not supported by #{adapter.class}"
      end

      def create_destination(name, dest_options={}, message_props={})
        raise 'Must be implemented in subclass'
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
    end
  end
end
