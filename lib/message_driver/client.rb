module MessageDriver
  module Client
    extend self

    def publish(destination, body, headers={}, properties={})
      dest = find_destination(destination)
      dest.publish(body, headers, properties)
    end

    def pop_message(destination, options={})
      dest = find_destination(destination)
      dest.pop_message(options)
    end

    def subscribe(destination_name, consumer_name)
      destination = find_destination(destination_name)
      consumer =  find_consumer(consumer_name)
      destination.subscribe(&consumer)
    end

    def with_message_transaction(options={}, &block)
      adapter.with_transaction(options, &block)
    end
    alias :with_transaction :with_message_transaction

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
