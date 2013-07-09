module MessageDriver
  module Adapters
    class Base
      attr_accessor :contexts

      def initialize(configuration)
        raise "Must be implemented in subclass"
      end

      def new_context
        raise "Must be implemented in subclass"
      end

      def stop
        contexts.each { |ctx| ctx.invalidate } if contexts
      end
    end

    class ContextBase
      attr_reader :adapter
      attr_accessor :valid

      def initialize(adapter)
        @adapter = adapter
        @adapter.contexts ||= []
        @adapter.contexts << self
        @valid = true
      end

      def publish(destination, body, headers={}, properties={})
        raise "Must be implemented in subclass"
      end

      def pop_message(destination, options={})
        raise "Must be implemented in subclass"
      end

      def subscribe(destination, options={}, &consumer)
        raise "#subscribe is not supported by #{adapter.class}"
      end

      def create_destination(name, dest_options={}, message_props={})
        raise "Must be implemented in subclass"
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
