module MessageDriver
  class Broker
    class << self
      def configure(adapter=MessageDriver::Adapter::InMemory.new)
        @adapter = adapter
      end

      def adapter
        @adapter
      end
    end
  end
end
