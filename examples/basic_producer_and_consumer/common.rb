require 'bundler/setup'
require 'message-driver'
require 'logger'

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG

MessageDriver.configure(
  adapter: 'bunny',
  vhost: 'message-driver-dev',
  heartbeat_interval: 2,
  logger: LOG
)

MessageDriver::Broker.define do |b|
  b.destination :basic_consumer_producer, 'basic.consumer.producer', durable: true
end
