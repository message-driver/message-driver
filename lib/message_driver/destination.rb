module MessageDriver
  module Destination
    class Base
      attr_reader :adapter, :name, :dest_options, :message_props

      def initialize(adapter, name, dest_options, message_props)
        @adapter = adapter
        @name = name
        @dest_options = dest_options
        @message_props = message_props
      end

      def publish(body, headers = {}, properties = {})
        current_adapter_context.publish(self, body, headers, properties)
      end

      def pop_message(options = {})
        current_adapter_context.pop_message(self, options)
      end

      def after_initialize(_adapter_context)
        # does nothing, feel free to override as needed
      end

      def message_count
        current_adapter_context.message_count(self)
      end

      def subscribe(options = {}, &consumer)
        current_adapter_context.subscribe(self, options, &consumer)
      end

      def consumer_count
        current_adapter_context.consumer_count(self)
      end

      def middleware
        @middleware ||= Middleware::MiddlewareStack.new(self)
      end

      private

      def current_adapter_context
        adapter.broker.client.current_adapter_context
      end

      def client
        @client ||= adapter.broker.client
      end
    end
  end
end
