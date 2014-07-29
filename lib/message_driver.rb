require 'message_driver/version'
require 'logger'

require 'message_driver/logging'
require 'message_driver/errors'
require 'message_driver/broker'
require 'message_driver/message'
require 'message_driver/middleware'
require 'message_driver/destination'
require 'message_driver/subscription'
require 'message_driver/adapters/base'
require 'message_driver/client'

module MessageDriver
  module_function
  def configure(broker_name = Broker::DEFAULT_BROKER_NAME, options)
    Broker.configure(broker_name, options)
  end

  def logger
    @__logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
  end

  def logger=(logger)
    @__logger = logger
  end
end
