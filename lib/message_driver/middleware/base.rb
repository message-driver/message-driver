module MessageDriver
  module Middleware
    class Base
      attr_reader :destination

      def initialize(*args)
        @destination = args.shift
      end

      def on_publish(body, headers, properties)
        [body, headers, properties]
      end

      def on_consume(body, headers, properties)
        [body, headers, properties]
      end
    end
  end
end
