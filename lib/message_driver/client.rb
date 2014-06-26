require 'forwardable'

module MessageDriver
  module Client
    include Logging
    extend self

    def publish(destination, body, headers={}, properties={})
      dest = find_destination(destination)
      current_adapter_context.publish(dest, body, headers, properties)
    end

    def pop_message(destination, options={})
      dest = find_destination(destination)
      current_adapter_context.pop_message(dest, options)
    end

    def subscribe(destination_name, consumer_name, options={})
      consumer =  find_consumer(consumer_name)
      subscribe_with(destination_name, options, &consumer)
    end

    def subscribe_with(destination_name, options={}, &consumer)
      destination = find_destination(destination_name)
      current_adapter_context.subscribe(destination, options, &consumer)
    end

    def dynamic_destination(dest_name, dest_options={}, message_props={})
      current_adapter_context.create_destination(dest_name, dest_options, message_props)
    end

    def ack_message(message, options={})
      message.ack(options)
    end

    def nack_message(message, options={})
      message.nack(options)
    end

    def consumer(key, &block)
      broker.consumer(key, &block)
    end

    def find_destination(destination)
      case destination
      when Destination::Base
        destination
      else
        broker.find_destination(destination)
      end
    end

    def find_consumer(consumer)
      broker.find_consumer(consumer)
    end

    def with_message_transaction(options={})
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

    def current_adapter_context(initialize=true)
      ctx = fetch_context_wrapper(initialize)
      ctx.nil? ? nil : ctx.ctx
    end

    def with_adapter_context(adapter_context)
      old_ctx, Thread.current[adapter_context_key] = fetch_context_wrapper(false), build_context_wrapper(adapter_context)
      begin
        yield
      ensure
        set_context_wrapper(old_ctx)
      end
    end

    def clear_context
      wrapper = fetch_context_wrapper(false)
      unless wrapper.nil?
        wrapper.invalidate
        set_context_wrapper(nil)
      end
    end

    def broker
      Broker.broker(broker_name)
    end

    def broker_name
      Broker::DEFAULT_BROKER_NAME
    end

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

    def [](index)
      Broker.client(index)
    end

    private

    def fetch_context_wrapper(initialize=true)
      wrapper = Thread.current[adapter_context_key]
      if wrapper.nil? || !wrapper.valid?
        if initialize
          wrapper = build_context_wrapper
        else
          wrapper = nil
        end
        Thread.current[adapter_context_key] = wrapper
      end
      wrapper
    end

    def set_context_wrapper(wrapper)
      Thread.current[adapter_context_key] = wrapper
    end

    def build_context_wrapper(ctx=adapter.new_context)
      ContextWrapper.new(ctx)
    end

    def adapter
      broker.adapter
    end

    def adapter_context_key
      @__adapter_context_key ||= "#{broker_name}_adapter_context".to_sym
    end

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
