require 'message_driver'

class TestRunner
  include MessageDriver::MessagePublisher

  attr_accessor :raised_error

  def config_broker(src)
    instance_eval(src)
  end

  def run_test_code(src)
    begin
      instance_eval(src)
    rescue => e
      @raised_error = e
    end
  end

  def fetch_messages(destination)
    result = []
    begin
      msg = pop_message(destination)
      result << msg unless msg.nil?
    end until msg.nil?
    result
  end
end

module KnowsMyTestRunner
  def test_runner
    @test_runner ||= TestRunner.new
  end
end

World(KnowsMyTestRunner)
