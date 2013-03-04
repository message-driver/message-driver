module MessageDriver
  class Broker
    class << self
      def configure(options={})
        opts = {adapter: :in_memory}.merge(options)
        @adapter = resolve_adapter(opts[:adapter])
      end

      def adapter
        @adapter
      end

      private

      def resolve_adapter(adapter)
        case adapter
        when Symbol
          resolve_adapter(find_adapter_class(adapter))
        when Class
          resolve_adapter(adapter.new)
        when MessageDriver::Adapter::Base
          adapter
        else
          raise "adapter must be a MessageDriver::Adapter::Base, but this object is a #{adapter.class}"
        end
      end

      def find_adapter_class(adapter_name)
        require "message_driver/adapter/#{adapter_name}"

        adapter_method = "#{adapter_name}_adapter"

        unless respond_to?(adapter_method)
          raise "the adapter #{adapter_name} must provide MessageDriver::Broker.#{adapter_method} that returns the adapter class"
        end

        send(adapter_method)
      end
    end
  end
end
