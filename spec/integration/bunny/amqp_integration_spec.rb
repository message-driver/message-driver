require 'spec_helper'

describe "AMQP Integration", :bunny, type: :integration do
  before(:each) do
    MessageDriver.configure BrokerConfig.config
  end
  after(:each) do
    MessageDriver::Broker.stop
  end

  context "when a queue can't be found" do
    let(:queue_name) { "my.lost.queue" }
    it "raises a MessageDriver::QueueNotFound error" do
      expect {
        MessageDriver::Broker.dynamic_destination(queue_name, passive: true)
      }.to raise_error(MessageDriver::QueueNotFound) do |err|
        expect(err.queue_name).to eq(queue_name)
        expect(err.nested).to be_a Bunny::NotFound
      end
    end
  end

  context "when a channel level exception occurs" do
    it "raises a MessageDriver::WrappedError error" do
      expect {
        MessageDriver::Broker.dynamic_destination("not.a.queue", passive: true)
      }.to raise_error(MessageDriver::WrappedError) { |err| err.nested.should be_a Bunny::ChannelLevelException }
    end

    it "reestablishes the channel transparently" do
      expect {
        MessageDriver::Broker.dynamic_destination("not.a.queue", passive: true)
      }.to raise_error(MessageDriver::WrappedError)
      expect {
        MessageDriver::Broker.dynamic_destination("", exclusive: true)
      }.to_not raise_error
    end

    context "when in a transaction" do
      it "sets the channel_context as rollback-only until the transaction is finished" do
        MessageDriver::Client.with_message_transaction do
          expect {
            MessageDriver::Broker.dynamic_destination("not.a.queue", passive: true)
          }.to raise_error(MessageDriver::WrappedError)
          expect {
            MessageDriver::Broker.dynamic_destination("", exclusive: true)
          }.to raise_error(MessageDriver::TransactionRollbackOnly)
        end
        expect {
          MessageDriver::Broker.dynamic_destination("", exclusive: true)
        }.to_not raise_error
      end
    end
  end

  context "when the broker connection fails", pending: "needs to be fixed" do
    def disrupt_connection
      #yes, this is very implementation specific
      MessageDriver::Broker.adapter.connection.instance_variable_get(:@transport).close
    end

    def create_destination(queue_name)
      MessageDriver::Broker.dynamic_destination(queue_name, exclusive: true)
    end

    it "raises a MessageDriver::ConnectionError" do
      dest = create_destination("test_queue")
      disrupt_connection
      expect {
        dest.publish("Reconnection Test")
      }.to raise_error(MessageDriver::ConnectionError) do |err|
        expect(err.nested).to be_a Bunny::NetworkErrorWrapper
      end
    end

    it "seemlessly reconnects" do
      dest = create_destination("seemless.reconnect.queue")
      disrupt_connection
      expect {
        dest.publish("Reconnection Test 1")
      }.to raise_error(MessageDriver::ConnectionError)
      dest = create_destination("seemless.reconnect.queue")
      dest.publish("Reconnection Test 2")
      msg = dest.pop_message
      expect(msg).to_not be_nil
      expect(msg.body).to eq("Reconnection Test 2")
    end

    context "when in a transaction" do
      it "raises a MessageDriver::ConnectionError" do
        expect {
          MessageDriver::Client.with_message_transaction do
            disrupt_connection
            MessageDriver::Broker.dynamic_destination("", exclusive: true)
          end
        }.to raise_error(MessageDriver::ConnectionError)
      end

      it "sets the channel_context as rollback-only until the transaction is finished" do
        MessageDriver::Client.with_message_transaction do
          disrupt_connection
          expect {
            MessageDriver::Broker.dynamic_destination("", exclusive: true)
          }.to raise_error(MessageDriver::ConnectionError)
          expect {
            MessageDriver::Broker.dynamic_destination("", exclusive: true)
          }.to raise_error(MessageDriver::TransactionRollbackOnly)
        end
        expect {
          MessageDriver::Broker.dynamic_destination("", exclusive: true)
        }.to_not raise_error
      end
    end
  end

  context "when an unhandled expection occurs in a transaction" do
    let(:destination) { MessageDriver::Broker.dynamic_destination("", exclusive: true) }

    it "rolls back the transaction" do
      expect {
        MessageDriver::Client.with_message_transaction do
          destination.publish("Test Message")
          raise "unhandled error"
        end
      }.to raise_error "unhandled error"
      expect(destination.pop_message).to be_nil
    end

    it "allows the next transaction to continue" do
      expect {
        MessageDriver::Client.with_message_transaction do
          destination.publish("Test Message 1")
          raise "unhandled error"
        end
      }.to raise_error "unhandled error"
      expect(destination.pop_message).to be_nil

      MessageDriver::Client.with_message_transaction do
        destination.publish("Test Message 2")
      end

      msg = destination.pop_message
      expect(msg).to_not be_nil
      expect(msg.body).to eq("Test Message 2")
    end
  end
end