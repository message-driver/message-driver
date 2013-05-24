module MessageDriver
  module Destination
    class Base
      attr_reader :adapter, :name, :dest_options, :message_props

      def initialize(adapter, name, dest_options, message_props)
        @adapter = adapter
        @name = name
        @dest_options = dest_options
        @message_props = message_props
        after_initialize
      end

      def publish(body, headers={}, properties={})
        @adapter.publish(@name, body, headers, @message_props.merge(properties))
      end

      def pop_message(options={})
        @adapter.pop_message(@name, options)
      end

      def subscribe(&consumer)
        @adapter.subscribe(@name, &consumer)
      end

      def after_initialize
        #does nothing, feel free to override as needed
      end

      def message_count
        raise "#message_count is not supported by #{self.class}"
      end
    end
  end
end
