class BaseProvider
  attr_accessor :broker_name, :read_queues_directly

  def initialize
    @read_queues_directly = false
  end

  def broker_name
    @broker_name ||= MessageDriver::Broker::DEFAULT_BROKER_NAME
  end

  def pause_if_needed(seconds = 0.1)
    seconds *= 10 if ENV['CI'] == 'true'
    case BrokerConfig.current_adapter
    when :in_memory
    else
      sleep seconds
    end
  end

  def fetch_messages(destination_name, _opts = {})
    destination = fetch_destination(destination_name)
    pause_if_needed
    result = []
    loop do
      msg = destination.pop_message
      if msg.nil?
        break
      else
        result << msg
      end
    end
    result
  end

  def purge_destination(destination_name, _opts = {})
    destination = fetch_destination(destination_name)
    if destination.respond_to? :purge
      destination.purge
    else
      fetch_messages(destination)
    end
  end

  def fetch_destination(destination)
    case destination
    when String, Symbol
      MessageDriver::Client[broker_name].find_destination(destination)
    when MessageDriver::Destination::Base
      destination
    else
      fail "didn't understand destination #{destination.inspect}"
    end
  end

  def fetch_current_adapter_context
    MessageDriver::Client[broker_name].current_adapter_context
  end
end
