module MessageDriver
  module MessageSender
    def send_message(destination, body, headers={})
      Broker.adapter.send_message(destination, body, headers={})
    end
  end
end
