module MessageDriver
  module Message
    class Base
      include Logging

      attr_reader :ctx, :body, :headers, :properties

      def initialize(ctx, body, headers, properties)
        @ctx = ctx
        @body = body
        @headers = headers
        @properties = properties
      end

      def ack(options={})
        if ctx.supports_client_acks?
          ctx.ack_message(self, options)
        else
          logger.debug('this adapter does not support client acks')
        end
      end

      def nack(options={})
        if ctx.supports_client_acks?
          ctx.nack_message(self, options)
        else
          logger.debug('this adapter does not support client acks')
        end
      end
    end
  end
end
