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

# Easy message queues for ruby
module MessageDriver
  module_function

  # (see MessageDriver::Broker.configure)
  def configure(name = Broker::DEFAULT_BROKER_NAME, options)
    Broker.configure(name, options)
  end

  # @!attribute [rw] logger
  # defaults to an +INFO+ level logger that logs to +STDOUT+
  # @return [Logger] the logger +MessageDriver+ will use for logging.
  def logger
    @__logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
  end

  def logger=(logger)
    @__logger = logger
  end
end
