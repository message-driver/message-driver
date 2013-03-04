require 'message_driver/version'

require 'message_driver/broker'
require 'message_driver/message'
require 'message_driver/adapter'
require 'message_driver/message_sender'
require 'message_driver/message_receiver'

module MessageDriver
  def self.configure(options={})
    Broker.configure(options)
  end
end
