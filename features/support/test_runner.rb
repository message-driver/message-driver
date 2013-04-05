require 'message_driver'

class TestRunner
  include MessageDriver::MessagePublisher
  include RSpec::Matchers

  attr_accessor :raised_error

  def config_broker(src)
    instance_eval(src)
  end

  def run_test_code(src)
    begin
      instance_eval(src)
    rescue Exception => e
      @raised_error = e
    end
  end

  def fetch_messages(destination)
    case destination
    when String, Symbol
      fetch_messages(MessageDriver::Broker.find_destination(destination))
    when MessageDriver::Destination::Base
      result = []
      begin
        msg = destination.pop_message
        result << msg unless msg.nil?
      end until msg.nil?
      result
    else
      raise "didn't understand destination #{destination}"
    end
  end

  def publish_table_to_destination(destination, table)
    table.hashes.each do |msg|
      destination.publish(msg[:body], msg[:headers]||{}, msg[:properties]||{})
    end
  end
end

module KnowsMyTestRunner
  def test_runner
    @test_runner ||= TestRunner.new
  end
end

World(KnowsMyTestRunner)
