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

    def subscribe(destination_name, options={}, consumer_name)
      destination = find_destination(destination_name)
      consumer =  find_consumer(consumer_name)
      current_adapter_context.subscribe(destination, options, &consumer)
    end

    def dynamic_destination(dest_name, dest_options={}, message_props={})
      current_adapter_context.create_destination(dest_name, dest_options, message_props)
    end

    def ack_message(message, options={})
      ctx = current_adapter_context
      if ctx.supports_client_acks?
        ctx.ack_message(message, options)
      else
        #TODO log a warning
      end
    end

    def nack_message(message, options={})
      ctx = current_adapter_context
      if ctx.supports_client_acks?
        ctx.nack_message(message, options)
      else
        #TODO log a warning
      end
    end

    def with_message_transaction(options={}, &block)
      transaction_depth = Thread.current[:_message_driver_transaction_depth] || 0
      transaction_depth += 1
      Thread.current[:_message_driver_transaction_depth] = transaction_depth
      ctx = current_adapter_context
      begin
        if transaction_depth == 1 && ctx.supports_transactions?
          ctx.begin_transaction(options)
          begin
            yield
            ctx.commit_transaction
          rescue
            begin
              ctx.rollback_transaction
            rescue
              #TODO log exception from rollback
            end
            raise
          end
        else
          yield
        end
      ensure
        transaction_depth -= 1
        Thread.current[:_message_driver_transaction_depth] = transaction_depth
      end
    end

    def current_adapter_context
      ctx = Thread.current[:adapter_context]
      if ctx.nil? || !ctx.valid?
        ctx = Broker.adapter.new_context
        Thread.current[:adapter_context] = ctx
      end
      ctx
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
      Broker.find_consumer(consumer)
    end

    def adapter
      Broker.adapter
    end
  end
end
