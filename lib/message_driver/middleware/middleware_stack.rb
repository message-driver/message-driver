module MessageDriver
  module Middleware
    class MiddlewareStack
      include Enumerable

      attr_reader :destination

      def initialize(destination)
        @destination = destination
        @middlewares = []
      end

      def middlewares
        @middlewares.dup.freeze
      end

      def append(middleware_class)
        middleware = build_middleware(middleware_class)
        @middlewares << middleware
        middleware
      end

      def prepend(middleware_class)
        middleware = build_middleware(middleware_class)
        @middlewares.unshift middleware
        middleware
      end

      def on_publish(body, headers, properties)
        @middlewares.reduce([body, headers, properties]) do |args, middleware|
          middleware.on_publish(*args)
        end
      end

      def on_consume(body, headers, properties)
        @middlewares.reverse.reduce([body, headers, properties]) do |args, middleware|
          middleware.on_consume(*args)
        end
      end

      def empty?
        @middlewares.empty?
      end

      def each
        @middlewares.each { |x| yield x }
      end

      private

      def build_middleware(middleware_class)
        middleware_class.new(destination)
      end
    end
  end
end
