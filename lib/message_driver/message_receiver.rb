module MessageDriver
  module MessageReceiver
    def pop_message(destination, options={})
      Broker.pop_message(destination, options)
    end
  end
end
