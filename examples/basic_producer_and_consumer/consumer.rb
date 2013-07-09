require_relative "./common"

LOG.info("starting consumer")

Thread.abort_on_exception = true

end_thread = Thread.new do
  Thread.stop
  LOG.info("stopping consumer")
  MessageDriver::Broker.stop
end

ending_proc = proc do
  end_thread.wakeup
end

trap "TERM", &ending_proc
trap "INT", &ending_proc

MessageDriver::Broker.consumer(:basic_consumer) do |message|
  LOG.info("I got a message! #{message.body}")
end

MessageDriver::Client.subscribe(:basic_consumer_producer, :basic_consumer)

end_thread.join
