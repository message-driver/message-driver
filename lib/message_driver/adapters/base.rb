module MessageDriver
  module Adapters
    class Base
      def initialize(configuration)
        raise "Must be implemented in subclass"
      end

      def publish(destination, body, headers={}, properties={})
        raise "Must be implemented in subclass"
      end

      def pop_message(destination, options={})
        raise "Must be implemented in subclass"
      end

      def stop
        raise "Must be implemented in subclass"
      end

      def create_destination(name, dest_options={}, message_props={})
        raise "Must be implemented in subclass"
      end

      def with_transaction(options={}, &block)
        raise "This adapter does not support transactions"
      end
    end
  end
end
