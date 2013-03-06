module MessageDriver
  class Broker
    class << self
      def configure(options)
        @adapter = resolve_adapter(options[:adapter], options)
        @configuration = options
      end

      def adapter
        @adapter
      end

      def configuration
        @configuration
      end

      def stop
        if @adapter
          @adapter.stop
        end
      end

      private

      def resolve_adapter(adapter, options)
        case adapter
        when nil
          raise "you must specify an adapter"
        when Symbol, String
          resolve_adapter(find_adapter_class(adapter), options)
        when Class
          resolve_adapter(adapter.new(options), options)
        when MessageDriver::Adapters::Base
          adapter
        else
          raise "adapter must be a MessageDriver::Adapters::Base, but this object is a #{adapter.class}"
        end
      end

      def find_adapter_class(adapter_name)
        require "message_driver/adapters/#{adapter_name}_adapter"

        adapter_method = "#{adapter_name}_adapter"

        unless respond_to?(adapter_method)
          raise "the adapter #{adapter_name} must provide MessageDriver::Broker.#{adapter_method} that returns the adapter class"
        end

        send(adapter_method)
      end
    end
  end
end
