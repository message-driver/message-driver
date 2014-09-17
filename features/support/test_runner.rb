require 'forwardable'

class TestRunner
  include MessageDriver::Client
  include RSpec::Matchers
  extend Forwardable

  attr_accessor :raised_error
  attr_accessor :current_feature_file

  def provider
    @provider ||= Provider.new
  end

  def_delegators :provider, :broker_name, :broker_name=, :fetch_messages, :fetch_destination, :fetch_current_adapter_context, :purge_destination, :pause_if_needed

  def run_config_code(src)
    instance_eval(src, current_feature_file)
  end

  def run_test_code(src)
    instance_eval(src, current_feature_file)
  rescue => e
    @raised_error = e
  end

  def publish_table_to_destination(destination, table)
    table.hashes.each do |msg|
      destination.publish(msg[:body], msg[:headers] || {}, msg[:properties] || {})
    end
  end
end

module KnowsMyTestRunner
  def test_runner
    @test_runner ||= TestRunner.new
  end
end

World(KnowsMyTestRunner)
