require 'forwardable'

module MessageDriver
  class Broker
    extend Forwardable

    attr_reader :adapter, :configuration, :destinations, :consumers

    def_delegators :@adapter, :stop

    class << self
      def configure(options)
        @instance = new(options)
      end

      def method_missing(m, *args, &block)
        @instance.send(m, *args, &block)
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
      @consumers = {}
    end

    def publish(destination, body, headers={}, properties={})
      dest = find_destination(destination)
      dest.publish(body, headers, properties)
    end

    def pop_message(destination, options={})
      dest = find_destination(destination)
      dest.pop_message(options)
    end

    def dynamic_destination(dest_name, dest_options={}, message_props={})
      adapter.create_destination(dest_name, dest_options, message_props)
    end

    def destination(key, dest_name, dest_options={}, message_props={})
      dest = dynamic_destination(dest_name, dest_options, message_props)
      @destinations[key] = dest
    end

    def consumer(key, &block)
      raise MessageDriver::Error, "you must provide a block" unless block_given?
      @consumers[key] = block
    end

    def subscribe(destination_name, consumer_name)
      destination = find_destination(destination_name)
      consumer =  find_consumer(consumer_name)
      destination.subscribe(&consumer)
    end

    def with_transaction(options={}, &block)
      adapter.with_transaction(options, &block)
    end

    private

    def find_destination(destination_name)
      destination = @destinations[destination_name]
      raise MessageDriver::NoSuchDestinationError, "no destination #{destination_name} has been configured" if destination.nil?
      destination
    end

    def find_consumer(consumer_name)
      @consumers[consumer_name]
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
