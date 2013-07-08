module MessageDriver
  module Client
    extend self

    def publish(destination, body, headers={}, properties={})
      dest = find_destination(destination)
      current_adapter_context.publish(dest, body, headers, properties)
    end

    def pop_message(destination, options={})
      dest = find_destination(destination)
      current_adapter_context.pop_message(dest, options)
    end

    def subscribe(destination_name, consumer_name)
      destination = find_destination(destination_name)
      consumer =  find_consumer(consumer_name)
      current_adapter_context.subscribe(destination, consumer)
    end

    def with_message_transaction(options={}, &block)
      current_adapter_context.with_transaction(options, &block)
    end

    def current_adapter_context
      ctx = Thread.current[:adapter_context]
      if ctx.nil? || !ctx.valid?
        ctx = Broker.adapter.new_context
        Thread.current[:adapter_context] = ctx
      end
      ctx
    end

    def current_adapter_context=(adapter_context)
      Thread.current[:adapter_context] = adapter_context
    end

    private
    def find_destination(destination)
      case destination
      when Destination::Base
        destination
      else
        Broker.find_destination(destination)
      end
    end

    def find_consumer(consumer)
      case consumer
      when Adapters::Base
        consumer
      else
        Broker.find_consumer(consumer)
      end
    end

    def adapter
      Broker.adapter
    end
  end
end
