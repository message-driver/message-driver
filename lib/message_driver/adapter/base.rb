module MessageDriver
  module Adapter
    class Base
      def send_message(destination, body, headers={}, properties={})
        raise "Must be implemented in subclass"
      end

      def pop_message(destination, options={})
        raise "Must be implemented in subclass"
      end
    end
  end
end
