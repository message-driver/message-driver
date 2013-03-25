require 'message_driver/version'

require 'message_driver/exceptions'
require 'message_driver/broker'
require 'message_driver/message'
require 'message_driver/destination'
require 'message_driver/adapters/base'
require 'message_driver/message_publisher'

module MessageDriver
  def self.configure(options={})
    Broker.configure(options)
  end

  def self.stop
    Broker.stop
  end
end
