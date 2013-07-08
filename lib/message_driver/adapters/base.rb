module MessageDriver
  module Adapters
    class Base
      attr_accessor :contexts

      def initialize(configuration)
        raise "Must be implemented in subclass"
      end

      def new_context
        ContextBase.new(self)
      end

      def stop
        contexts.each { |ctx| ctx.valid = false } if contexts
      end
    end

    class ContextBase
      attr_reader :adapter
      attr_accessor :valid

      def initialize(adapter)
        @adapter = adapter
        @adapter.contexts ||= []
        @adapter.contexts << self
        @valid = true
      end

      #def publish(destination, body, headers={}, properties={})
        #raise "Must be implemented in subclass"
      #end

      #def pop_message(destination, options={})
        #raise "Must be implemented in subclass"
      #end

      #def subscribe(destination, consumer)
        #raise "Must be implemented in subclass"
      #end

      #def create_destination(name, dest_options={}, message_props={})
        #raise "Must be implemented in subclass"
      #end

      #def with_transaction(options={}, &block)
        #raise "Must be implemented in subclass"
      #end

      def valid?
        @valid
      end

      #temporary implementations for while we are refactoring
      def publish(destination, body, headers={}, properties={})
        destination.publish(body, headers, properties)
      end

      def pop_message(destination, options={})
        destination.pop_message(options)
      end

      def subscribe(destination, consumer)
        destination.subscribe(&consumer)
      end

      def create_destination(name, dest_options={}, message_props={})
        raise "Must be implemented in subclass"
      end

      def with_transaction(options={}, &block)
        adapter.with_transaction(options, &block)
      end
    end
  end
end
