require 'stomp'

module MessageDriver
  class Broker
    def stomp_adapter
      MessageDriver::Adapters::StompAdapter
    end
  end

  module Adapters
    class StompAdapter < Base

      class Message < MessageDriver::Message::Base
        attr_reader :stomp_message
        def initialize(stomp_message)
          @stomp_message = stomp_message
          super(stomp_message.body, stomp_message.headers, {})
        end
      end

      attr_reader :config, :poll_timeout

      def initialize(config)
        validate_stomp_version

        @config = config.symbolize_keys
        connect_headers = @config[:connect_headers] ||= {}
        connect_headers.symbolize_keys
        connect_headers[:"accept-version"] = "1.1,1.2"

        vhost = @config.delete(:vhost)
        connect_headers[:host] = vhost if vhost

        @poll_timeout = 1
      end

      def with_connection
        begin
          @connection ||= open_connection
          yield @connection
        rescue SystemCallError, IOError => e
          raise MessageDriver::ConnectionException.new(e)
        end
      end

      def create_destination(name, dest_options={}, message_props={})
        unless name.start_with?("/")
          name = "/queue/#{name}"
        end
        MessageDriver::Destination::Base.new(self, name, dest_options, message_props)
      end

      def publish(destination, body, headers={}, properties={})
        with_connection do |connection|
          connection.publish(destination, body, headers)
        end
      end

      def pop_message(destination, options={})
        with_connection do |connection|
          sub_id = connection.uuid
          msg = nil
          count = 0
          options[:id] = sub_id #this is a workaround for https://github.com/stompgem/stomp/issues/56
          connection.subscribe(destination, options, sub_id)
          while msg.nil? && count < max_poll_count
            msg = connection.poll
            if msg.nil?
              count += 1
              sleep 0.1
            end
          end
          connection.unsubscribe(destination, options, sub_id)
          Message.new(msg) if msg
        end
      end

      def stop
        if @connection
          @connection.disconnect
        end
      end

      private

      def open_connection
        conn = Stomp::Connection.new(@config)
        raise MessageDriver::ConnectionException, conn.connection_frame.to_s unless conn.open?
        conn
      end

      def validate_stomp_version
        required = Gem::Requirement.create('~> 1.2.9')
        current = Gem::Version.create(Stomp::Version::STRING)
        unless required.satisfied_by? current
          raise MessageDriver::Exception, "stomp 1.2.9 or a later version of the 1.2.x series is required for the stomp adapter"
        end
      end

      def max_poll_count
        (poll_timeout / 0.1).to_i
      end
    end
  end
end