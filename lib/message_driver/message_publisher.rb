module MessageDriver
  module MessagePublisher
    def publish(destination, body, headers={}, properties={})
      Broker.publish(destination, body, headers, properties)
    end
  end
end
