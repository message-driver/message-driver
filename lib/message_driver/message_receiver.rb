module MessageDriver
  module MessageReceiver
    def pop_message(destination, options={})
      Broker.adapter.pop_message(destination, options={})
    end
  end
end
