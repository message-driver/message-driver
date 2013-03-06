module MessageDriver
  module Adapters
    class Base
      def initialize(configuration)
        raise "Must be implemented in subclass"
      end

      def send_message(destination, body, headers={}, properties={})
        raise "Must be implemented in subclass"
      end

      def pop_message(destination, options={})
        raise "Must be implemented in subclass"
      end

      def stop
        raise "Must be implemented in subclass"
      end

      def create_destination(destination, options={})
        raise "Must be implemented in subclass"
      end
    end
  end
end
