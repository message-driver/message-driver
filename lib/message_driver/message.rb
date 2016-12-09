module MessageDriver
  module Message
    class Base
      include Logging

      attr_reader :ctx, :destination, :body, :raw_body, :headers, :properties

      def initialize(ctx, destination, body, headers, properties, raw_body = nil)
        @ctx = ctx
        @destination = destination
        @body = body
        @headers = headers
        @properties = properties
        @raw_body = raw_body.nil? ? body : raw_body
      end

      def ack(options = {})
        if ctx.supports_client_acks?
          ctx.ack_message(self, options)
        else
          logger.debug('this adapter does not support client acks')
        end
      end

      def nack(options = {})
        if ctx.supports_client_acks?
          ctx.nack_message(self, options)
        else
          logger.debug('this adapter does not support client acks')
        end
      end
    end
  end
end
