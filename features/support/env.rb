require File.join(File.dirname(__FILE__), '..', '..', 'test_lib', 'broker_config')

require 'message_driver'

#World(MessageDriver::MessagePublisher)

After do
  MessageDriver.stop
end
