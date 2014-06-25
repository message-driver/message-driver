class TestRunner
  include MessageDriver::Client
  include RSpec::Matchers

  attr_accessor :raised_error
  attr_accessor :current_feature_file
  attr_accessor :broker_name

  def broker_name
    @broker_name ||= MessageDriver::Broker::DEFAULT_BROKER_NAME
  end

  def run_config_code(src)
    instance_eval(src, current_feature_file)
  end

  def run_test_code(src)
    begin
      instance_eval(src, current_feature_file)
    rescue => e
      @raised_error = e
    end
  end

  def fetch_messages(destination_name)
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

  def purge_destination(destination_name)
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
      MessageDriver::Client[self.broker_name].find_destination(destination)
    when MessageDriver::Destination::Base
      destination
    else
      raise "didn't understand destination #{destination.inspect}"
    end
  end

  def publish_table_to_destination(destination, table)
    table.hashes.each do |msg|
      destination.publish(msg[:body], msg[:headers]||{}, msg[:properties]||{})
    end
  end

  def pause_if_needed(seconds=0.1)
    seconds *= 10 if ENV['CI'] == 'true'
    case BrokerConfig.current_adapter
    when :in_memory
    else
      sleep seconds
    end
  end
end

module KnowsMyTestRunner
  def test_runner
    @test_runner ||= TestRunner.new
  end
end

World(KnowsMyTestRunner)
