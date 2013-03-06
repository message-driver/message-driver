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

      def send_message(body, headers={}, properties={})
        @adapter.send_message(@name, body, headers, @message_props.merge(properties))
      end

      def pop_message(options={})
        @adapter.pop_message(@name, options)
      end

      def after_initialize
        #does nothing, feel free to override as needed
      end
    end
  end
end
