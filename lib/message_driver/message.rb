module MessageDriver
  module Message
    class Base
      attr_reader :body, :headers, :properties

      def initialize(body, headers, properties)
        @body = body
        @headers = headers
        @properties = properties
      end
    end
  end
end
