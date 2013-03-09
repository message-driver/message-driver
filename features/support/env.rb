require File.join(File.dirname(__FILE__), '..', '..', 'test_lib', 'broker_config')

require 'message_driver'

Before do
  MessageDriver.configure(BrokerConfig.config)
end

After do
  MessageDriver.stop
end
