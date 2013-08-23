require 'message_driver/version'

require 'message_driver/errors'
require 'message_driver/broker'
require 'message_driver/logging'
require 'message_driver/message'
require 'message_driver/destination'
require 'message_driver/subscription'
require 'message_driver/adapters/base'
require 'message_driver/client'

module MessageDriver
  def self.configure(options={})
    Broker.configure(options)
  end

  def self.stop
    Broker.stop
  end
end
