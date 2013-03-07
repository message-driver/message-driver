module MessageDriver
  module MessagePublisher
    def publish(destination, body, headers={}, properties={})
      Broker.publish(destination, body, headers, properties)
    end

    def pop_message(destination, options={})
      Broker.pop_message(destination, options)
    end
  end
end
