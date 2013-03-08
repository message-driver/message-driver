require 'forwardable'

module MessageDriver
  class Broker
    extend Forwardable

    attr_reader :adapter, :configuration, :with_transaction

    def_delegators :@adapter, :stop

    class << self
      def configure(options)
        @instance = new(options)
      end

      def method_missing(m, *args)
        @instance.send(m, *args)
      end

      def with_transaction(options, &block)
        @instance.with_transaction(options, &block)
      end

      def instance
        @instance
      end

      def define
        yield @instance
      end
    end

    def initialize(options)
      @adapter = resolve_adapter(options[:adapter], options)
      @configuration = options
      @destinations = {}
    end

    def publish(destination, body, headers={}, properties={})
      dest = find_destination(destination)
      dest.publish(body, headers, properties)
    end

    def pop_message(destination, options={})
      dest = find_destination(destination)
      dest.pop_message(options)
    end

    def destination(key, dest_name, dest_options={}, message_props={})
      dest = adapter.create_destination(dest_name, dest_options, message_props)
      @destinations[key] = dest
    end

    def with_transaction(options={}, &block)
      adapter.with_transaction(options, &block)
    end

    private

    def find_destination(destination)
      @destinations[destination]
    end

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
