module MessageDriver
  module MessageSender
    def send_message(destination, body, headers={}, properties={})
      Broker.adapter.send_message(destination, body, headers, properties)
    end
  end
end
