module MessageDriver
  class Broker
    class << self
      def configure(config_file="config/message_driver.yml")
        @adapter = MessageDriver::Adapter::InMemory.new
      end

      def adapter
        @adapter
      end
    end
  end
end
