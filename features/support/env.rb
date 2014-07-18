if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

require File.join(File.dirname(__FILE__), '..', '..', 'test_lib', 'broker_config')

require 'aruba/cucumber'
require 'message_driver'

After do
  MessageDriver::Broker.reset
end
