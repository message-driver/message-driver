require_relative "./common"

LOG.info("starting producer")

stopping = false

ending_proc = proc do
  stopping = true
end

trap "TERM", &ending_proc
trap "INT", &ending_proc

counter = 0

while !stopping do
  10.times do
    counter += 1
    MessageDriver::Client.publish(:basic_consumer_producer, "message #{counter}")
  end
  LOG.info("sent 10 more messages for a total of #{counter}")
  sleep 1
end

LOG.info("stopping producer")
MessageDriver::Broker.stop
