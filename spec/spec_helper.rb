ENV['COMMAND_NAME'] = 'specs'
require File.join(File.dirname(__FILE__), '..', 'test_lib', 'coverage')
require File.join(File.dirname(__FILE__), '..', 'test_lib', 'broker_config')

require 'message_driver'

BrokerConfig.setup_provider

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |c|
  c.order = :random
  c.filter_run :focus

  c.reporter.message("Acceptance Tests running with broker config: #{BrokerConfig.config}")

  spec_logger = Logger.new(STDOUT).tap { |l| l.level = Logger::FATAL }
  c.before(:example) do
    MessageDriver.logger = spec_logger
  end

  c.after(:example) do
    MessageDriver::Broker.reset
  end

  c.filter_run_excluding :no_ci if ENV['CI'] == 'true' && ENV['ADAPTER'] && ENV['ADAPTER'].start_with?('bunny')
  if c.inclusion_filter[:all_adapters] == true
    BrokerConfig.unconfigured_adapters.each do |a|
      c.filter_run_excluding a
    end
    c.filter_run_including BrokerConfig.current_adapter
  else
    c.run_all_when_everything_filtered = true
  end

  c.expose_dsl_globally = false
end
