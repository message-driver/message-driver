module MessageDriver
  module Middleware
    class BlockMiddleware < Base
      attr_reader :on_publish_block, :on_consume_block

      def initialize(destination, opts)
        super(destination)
        raise ArgumentError, 'you must provide at least one of :on_publish and :on_consume' \
          unless opts.keys.any? { |k| [:on_publish, :on_consume].include? k }
        @on_publish_block = opts[:on_publish]
        @on_consume_block = opts[:on_consume]
      end

      def on_publish(body, headers, properties)
        delegate_to_block(on_publish_block, body, headers, properties)
      end

      def on_consume(body, headers, properties)
        delegate_to_block(on_consume_block, body, headers, properties)
      end

      private

      def delegate_to_block(block, body, headers, properties)
        if block.nil?
          [body, headers, properties]
        else
          block.call(body, headers, properties)
        end
      end
    end
  end
end
