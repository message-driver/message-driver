module MessageDriver
  class Broker
    include Logging

    DEFAULT_BROKER_NAME = :default

    attr_reader :adapter, :configuration, :destinations, :consumers, :name

    class << self
      def configure(name = DEFAULT_BROKER_NAME, options)
        if brokers.keys.include? name
          raise BrokerAlreadyConfigured, "there is already a broker named #{name} configured"
        end
        brokers[name] = new(name, options)
      end

      def method_missing(m, *args, &block)
        STDERR.puts "#{self.name}.#{m} directly is deprecated, please use MessageDriver::Client.#{m} or #{self.name}.broker.#{m} instead"
        STDERR.puts "called from #{Thread.current.backtrace[2]}"
        if public_method_defined? m
          broker.__send__(m, *args, &block)
        else
          super
        end
      end

      def instance
        STDERR.puts "#{self.name}.instance is deprecated, please use #{self.name}.broker instead"
        STDERR.puts "called from #{Thread.current.backtrace[2]}"
        broker
      end

      def define(name = DEFAULT_BROKER_NAME)
        yield broker(name)
      end

      def broker(name = DEFAULT_BROKER_NAME)
        result = brokers[name]
        if result.nil?
          raise BrokerNotConfigured, "There is no broker named #{name} configured. The configured brokers are #{brokers.keys}"
        end
        result
      end

      def stop
        each_broker do |brk|
          brk.stop
        end
      end

      def reset
        each_broker do |brk|
          begin
            brk.stop
          rescue => e
            Logging.logger.warn Logging.message_with_exception("error stopping broker #{brk.name}", e)
          end
        end
        brokers.clear
      end

      private
      def brokers
        @brokers ||= { }
      end

      def each_broker
        brokers.keys.each do |k|
          yield brokers[k]
        end
      end
    end

    def initialize(name = DEFAULT_BROKER_NAME, options)
      @name = name
      @adapter = resolve_adapter(options[:adapter], options)
      @stopped = false
      @configuration = options
      @destinations = {}
      @consumers = {}
      logger.debug "MessageDriver configured successfully!"
    end

    def logger
      MessageDriver.logger
    end

    def client
      @client ||= Client.for_broker(name)
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
      client.dynamic_destination(dest_name, dest_options, message_props)
    end

    def destination(key, dest_name, dest_options={}, message_props={})
      dest = self.dynamic_destination(dest_name, dest_options, message_props)
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
        resolve_adapter(adapter.new(self, options), options)
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
        raise "the adapter #{adapter_name} must provide MessageDriver::Broker##{adapter_method} that returns the adapter class"
      end

      send(adapter_method)
    end
  end
end
