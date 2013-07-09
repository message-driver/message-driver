module MessageDriver
  module Message
    class Base
      attr_reader :body, :headers, :properties

      def initialize(body, headers, properties)
        @body = body
        @headers = headers
        @properties = properties
      end

      def ack(options={})
        Client.ack_message(self, options)
      end

      def nack(options={})
        Client.nack_message(self, options)
      end
    end
  end
end
