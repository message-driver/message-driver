require 'message_driver'

class TestRunner
  include MessageDriver::Client
  include RSpec::Matchers

  attr_accessor :raised_error
  attr_accessor :current_feature_file

  def run_config_code(src)
    instance_eval(src, current_feature_file)
  end

  def run_test_code(src)
    begin
      instance_eval(src, current_feature_file)
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
