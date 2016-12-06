require 'forwardable'

module MessageDriver
  # The client module is the primary client API for MessageDriver. It can either be
  # included in a class that is using it, or used directly.
  #
  # @example Included as a Module
  #   class MyClass
  #     include MessageDriver::Client
  #
  #     def do_work
  #       publish(:my_destination, 'Hi Mom!')
  #     end
  #   end
  #
  # @example Used Directly
  #   class DirectClass
  #     def use_directly
  #       MesageDriver::Client.find_destination(:my_queue)
  #     end
  #   end
  module Client
    include Logging
    extend self # rubocop:disable Style/ModuleFunction

    # @!group Defining and Looking up Destinations

    def dynamic_destination(dest_name, dest_options = {}, message_props = {})
      current_adapter_context.create_destination(dest_name, dest_options, message_props)
    end

    # (see MessageDriver::Broker#find_destination)
    # @note if +destination_name+ is a {Destination::Base}, +find_destination+ will just
    #   return that destination back
    def find_destination(destination_name)
      case destination_name
      when Destination::Base
        destination_name
      else
        broker.find_destination(destination_name)
      end
    end

    # @!endgroup

    # @!group Defining and Looking Up Consumers

    def consumer(key, &block)
      broker.consumer(key, &block)
    end

    def find_consumer(consumer)
      broker.find_consumer(consumer)
    end

    # @!endgroup

    # @!group Sending Messages

    def publish(destination, body, headers = {}, properties = {})
      find_destination(destination).publish(body, headers, properties)
    end

    # @!endgroup

    # @!group Receiving Messages

    def pop_message(destination, options = {})
      find_destination(destination).pop_message(options)
    end

    def ack_message(message, options = {})
      message.ack(options)
    end

    def nack_message(message, options = {})
      message.nack(options)
    end

    def subscribe(destination_name, consumer_name, options = {})
      consumer = find_consumer(consumer_name)
      subscribe_with(destination_name, options, &consumer)
    end

    def subscribe_with(destination_name, options = {}, &consumer)
      destination = find_destination(destination_name)
      current_adapter_context.subscribe(destination, options, &consumer)
    end

    # @!endgroup

    # @!group Transaction Management

    def with_message_transaction(options = {})
      wrapper = fetch_context_wrapper
      wrapper.increment_transaction_depth
      begin
        if wrapper.ctx.supports_transactions?
          if wrapper.transaction_depth == 1
            wrapper.ctx.begin_transaction(options)
            begin
              yield
            rescue
              begin
                wrapper.ctx.rollback_transaction
              rescue => e
                logger.error exception_to_str(e)
              end
              raise
            end
            wrapper.ctx.commit_transaction
          else
            yield
          end
        else
          logger.debug('this adapter does not support transactions')
          yield
        end
      ensure
        wrapper.decrement_transaction_depth
      end
    end

    # @!endgroup

    # @private
    def current_adapter_context(initialize = true)
      ctx = fetch_context_wrapper(initialize)
      ctx.nil? ? nil : ctx.ctx
    end

    # @private
    def with_adapter_context(adapter_context)
      old_ctx = fetch_context_wrapper(false)
      Thread.current[adapter_context_key] = build_context_wrapper(adapter_context)
      begin
        yield
      ensure
        set_context_wrapper(old_ctx)
      end
    end

    # @private
    def clear_context
      wrapper = fetch_context_wrapper(false)
      unless wrapper.nil?
        wrapper.invalidate
        set_context_wrapper(nil)
      end
    end

    # @return [Broker] the broker associated with this Client module
    def broker
      Broker.broker(broker_name)
    end

    # @return [Symbol] the name of the broker associated with this Client module
    def broker_name
      Broker::DEFAULT_BROKER_NAME
    end

    # @private
    def for_broker(name)
      Module.new do
        include Client
        extend self

        define_method :broker_name do
          name
        end
      end
    end
    module_function :for_broker

    # @return [Client] the client for the specified broker
    # @example
    #   class MyClass
    #     include MessageDriver::Client[:my_broker]
    #   end
    def [](index)
      Broker.client(index)
    end

    private

    def fetch_context_wrapper(initialize = true)
      wrapper = Thread.current[adapter_context_key]
      if wrapper.nil? || !wrapper.valid?
        wrapper = (build_context_wrapper if initialize)
        Thread.current[adapter_context_key] = wrapper
      end
      wrapper
    end

    def set_context_wrapper(wrapper)
      Thread.current[adapter_context_key] = wrapper
    end

    def build_context_wrapper(ctx = adapter.new_context)
      ContextWrapper.new(ctx)
    end

    def adapter
      broker.adapter
    end

    def adapter_context_key
      @__adapter_context_key ||= "#{broker_name}_adapter_context".to_sym
    end

    # @private
    class ContextWrapper
      extend Forwardable

      def_delegators :@ctx, :valid?, :invalidate

      attr_reader :ctx
      attr_reader :transaction_depth

      def initialize(ctx)
        @ctx = ctx
        @transaction_depth = 0
      end

      def increment_transaction_depth
        @transaction_depth += 1
      end

      def decrement_transaction_depth
        @transaction_depth -= 1
      end
    end
  end
end
