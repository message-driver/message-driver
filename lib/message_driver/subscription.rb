module MessageDriver
  module Subscription
    class Base
      attr_reader :adapter, :destination, :consumer

      def initialize(adapter, destination, consumer)
        @adapter = adapter
        @destination = destination
        @consumer = consumer
      end

      def unsubscribe
        raise "must be implemented in subclass"
      end
    end
  end
end
