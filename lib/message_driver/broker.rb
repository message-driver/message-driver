require 'forwardable'
require 'logger'

module MessageDriver
  class Broker
    extend Forwardable

    attr_reader :adapter, :configuration, :destinations, :consumers, :logger

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
      @stopped = false
      @configuration = options
      @destinations = {}
      @consumers = {}
      @logger = options[:logger] || Logger.new(STDOUT).tap{|l| l.level = Logger::INFO}
      logger.debug "MessageDriver configured successfully!"
    end

    def stop
      @adapter.stop
      @stopped = true
    end

    def stopped?
      @stopped
    end

    def restart
      unless stopped?
        @adapter.stop
      end
      @adapter = resolve_adapter(@configuration[:adapter], @configuration)
      @stopped = false
    end

    def dynamic_destination(dest_name, dest_options={}, message_props={})
      Client.dynamic_destination(dest_name, dest_options, message_props)
    end

    def destination(key, dest_name, dest_options={}, message_props={})
      dest = Client.dynamic_destination(dest_name, dest_options, message_props)
      @destinations[key] = dest
    end

    def consumer(key, &block)
      raise MessageDriver::Error, "you must provide a block" unless block_given?
      @consumers[key] = block
    end

    def find_destination(destination_name)
      destination = @destinations[destination_name]
      raise MessageDriver::NoSuchDestinationError, "no destination #{destination_name} has been configured" if destination.nil?
      destination
    end

    def find_consumer(consumer_name)
      consumer = @consumers[consumer_name]
      raise MessageDriver::NoSuchConsumerError, "no consumer #{consumer_name} has been configured" if consumer.nil?
      consumer
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
