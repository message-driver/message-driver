require_relative 'base'
require 'rabbitmq/http/client'

class RabbitmqProvider < BaseProvider
  class Context
    def self.supports_client_acks?
      false
    end
  end

  def fetch_messages(destination_name, opts = {})
    if read_queues_directly
      super
    else
      destination = fetch_destination(destination_name)
      pause_if_needed
      result = []
      loop do
        msgs = rabbitmq.get_messages(vhost, destination.name, { count: 10, requeue: false, encoding: 'auto' }.merge(opts))
        msgs.each do |msg|
          if msg.nil?
            break
          else
            result << build_message(msg)
          end
        end
        break if msgs.nil? || msgs.empty?
      end
      result
    end
  end

  def purge_destination(destination_name, opts = {})
    not_exists_ok = opts.fetch(:not_exists_ok, true)
    if read_queues_directly
      super
    else
      destination = fetch_destination(destination_name)
      begin
        rabbitmq.purge_queue(vhost, destination.name)
      rescue Faraday::ResourceNotFound
        raise unless not_exists_ok
      end
    end
  end

  private

  def build_message(data)
    props = data.properties.dup
    headers = props.delete(:headers)
    MessageDriver::Message::Base.new(Context, data.payload, headers, props)
  end

  def vhost
    @vhost ||= BrokerConfig.config[:vhost]
  end

  def rabbitmq
    @rabbitmq ||= begin
      endpoint = 'http://127.0.0.1:15672'
      RabbitMQ::HTTP::Client.new(endpoint, username: 'guest', password: 'guest')
    end
  end
end

Provider = RabbitmqProvider
