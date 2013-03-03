module MessageDriver
  module Adapter
    class InMemory < Base
      def initialize
        @messages
      end

      def send_message(destination, body, headers={})
        message_store[destination] << {:body => body, :headers => headers}
      end

      def pop_message(destination, options={})
        message_store[destination].shift
      end

      private

      def message_store
        @message_store ||= Hash.new { |h,k| h[k] = [] }
      end

      class Message < MessageDriver::Message::Base

      end
    end
  end
end
