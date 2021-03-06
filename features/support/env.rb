ENV['COMMAND_NAME'] = 'features'
require File.join(File.dirname(__FILE__), '..', '..', 'test_lib', 'coverage')
require File.join(File.dirname(__FILE__), '..', '..', 'test_lib', 'broker_config')

require 'aruba/cucumber'
require 'message_driver'

BrokerConfig.setup_provider

After do
  MessageDriver::Broker.reset
end
