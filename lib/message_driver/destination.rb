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

      def publish(body, headers={}, properties={})
        adapter.broker.client.publish(self, body, headers, properties)
      end

      def pop_message(options={})
        adapter.broker.client.pop_message(self, options)
      end

      def after_initialize(adapter_context)
        #does nothing, feel free to override as needed
      end

      def message_count
        raise "#message_count is not supported by #{self.class}"
      end

      def subscribe(&consumer)
        raise "#subscribe is not supported by #{self.class}"
      end
    end
  end
end
