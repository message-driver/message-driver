require 'bundler/setup'
require 'pry'
require 'message-driver'

MessageDriver.configure(
  adapter: "bunny",
  vhost: "message-driver-dev"
)

MessageDriver::Broker.define do |b|
  b.destination :basic_consumer_producer, "basic.consumer.producer"
end

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG
