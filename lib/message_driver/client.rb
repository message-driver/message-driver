module MessageDriver
  module Client
    extend self

    def publish(destination, body, headers={}, properties={})
      Broker.publish(destination, body, headers, properties)
    end

    def pop_message(destination, options={})
      Broker.pop_message(destination, options)
    end

    def with_message_transaction(options={}, &block)
      Broker.with_transaction(options, &block)
    end
  end
end
