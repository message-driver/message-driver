module MessageDriver
  class Broker
    include Logging

    DEFAULT_BROKER_NAME = :default

    attr_reader :adapter
    attr_reader :configuration
    attr_reader :name

    # @private
    attr_reader :destinations, :consumers

    class << self
      # @overload configure(options)
      # @overload configure(name, options)
      # @param name [Symbol] when configuring multiple brokers, this symbol will differentiate between brokers
      # @param options [Hash] options to be passed to the adapter class
      def configure(name = DEFAULT_BROKER_NAME, options)
        if brokers.keys.include? name
          raise BrokerAlreadyConfigured, "there is already a broker named #{name} configured"
        end
        brokers[name] = new(name, options)
      end

      # @overload broker
      # @overload broker(name)
      # @param name [Symbol] the name of the broker you wish to define
      # @return [Broker] the specified broker
      # @raise [BrokerNotConfigured] if a broker by that name has not yet been configured
      def broker(name = DEFAULT_BROKER_NAME)
        result = brokers[name]
        if result.nil?
          raise BrokerNotConfigured,
                "There is no broker named #{name} configured. The configured brokers are #{brokers.keys}"
        end
        result
      end

      # Yields the specified broker so that destinations and consumers can be defined on it.
      # @overload define
      # @overload define(name)
      # @param (see #broker)
      # @yield [Broker] the specified broker
      # @raise (see #broker)
      def define(name = DEFAULT_BROKER_NAME)
        yield broker(name)
      end

      # @private
      def client(name)
        unless (result = clients[name])
          result = clients[name] = Client.for_broker(name)
        end
        result
      end

      # stops all the brokers
      # @see #stop
      def stop_all
        each_broker(&:stop)
      end

      # restarts all the brokers
      # @see #restart
      def restart_all
        each_broker(&:restart)
      end

      # Resets all the brokers for testing purposes.
      # @see Adapter::Base#reset_after_tests
      def reset_after_tests
        each_broker do |brk|
          brk.adapter.reset_after_tests
        end
      end

      # Stops and un-configures all the brokers
      # @see #stop
      def reset
        each_broker do |brk|
          begin
            brk.stop
          rescue => e
            Logging.logger.warn Logging.message_with_exception("error stopping broker #{brk.name}", e)
          end
        end
        brokers.clear
        clients.clear
      end

      private

      def brokers
        @brokers ||= {}
      end

      def clients
        @clients ||= {}
      end

      def each_broker
        brokers.keys.each do |k|
          yield brokers[k]
        end
      end
    end

    # @private
    def initialize(name = DEFAULT_BROKER_NAME, options)
      @name = name
      @adapter = resolve_adapter(options[:adapter], options)
      @stopped = false
      @configuration = options
      @destinations = {}
      @consumers = {}
      logger.debug 'MessageDriver configured successfully!'
    end

    # @return [MessageDriver::Client] the client module for this broker
    def client
      @client ||= self.class.client(name)
    end

    # stops the adapter for this Broker
    # @see Adapters::Base#stop
    def stop
      @adapter.stop
      @stopped = true
    end

    # @return [Boolean] true if the broker is currently stopped
    def stopped?
      @stopped
    end

    # Restarts the Broker, stopping it first if needed. This results in a new
    #   adapter instance being constructed.
    # @return [Adapter::Base] the newly constructed adapter
    def restart
      @adapter.stop unless stopped?
      @adapter = resolve_adapter(@configuration[:adapter], @configuration)
      @stopped = false
      @adapter
    end

    def dynamic_destination(dest_name, dest_options = {}, message_props = {})
      client.dynamic_destination(dest_name, dest_options, message_props)
    end

    def destination(key, dest_name, dest_options = {}, message_props = {})
      dest = dynamic_destination(dest_name, dest_options, message_props)
      @destinations[key] = dest
    end

    def consumer(key, &block)
      raise MessageDriver::Error, 'you must provide a block' unless block_given?
      @consumers[key] = block
    end

    # Find a previously declared Destination
    # @param destination_name [Symbol] the name of the destination
    # @return [Destination::Base] the requested destination
    # @raise [MessageDriver::NoSuchDestinationError] if there is no destination with that name
    def find_destination(destination_name)
      destination = @destinations[destination_name]
      if destination.nil?
        raise MessageDriver::NoSuchDestinationError, "no destination #{destination_name} has been configured"
      end
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
        raise 'you must specify an adapter'
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
        raise ['the adapter',
               adapter_name,
               'must provide',
               "MessageDriver::Broker##{adapter_method}",
               'that returns the adapter class'].join(' ')
      end

      send(adapter_method)
    end
  end
end
