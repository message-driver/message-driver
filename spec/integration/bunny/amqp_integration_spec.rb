require 'spec_helper'

describe 'AMQP Integration', :bunny, type: :integration do
  let!(:broker) { MessageDriver::Broker.configure BrokerConfig.config }

  context "when a queue can't be found" do
    let(:queue_name) { 'my.lost.queue' }
    it 'raises a MessageDriver::QueueNotFound error' do
      expect do
        broker.dynamic_destination(queue_name, passive: true)
      end.to raise_error(MessageDriver::QueueNotFound) do |err|
        expect(err.nested).to be_a Bunny::NotFound
      end
    end
  end

  context 'when a channel level exception occurs' do
    it 'raises a MessageDriver::WrappedError error' do
      expect do
        broker.dynamic_destination('not.a.queue', passive: true)
      end.to raise_error(MessageDriver::WrappedError) { |err| expect(err.nested).to be_a Bunny::ChannelLevelException }
    end

    it 'reestablishes the channel transparently' do
      expect do
        broker.dynamic_destination('not.a.queue', passive: true)
      end.to raise_error(MessageDriver::WrappedError)
      expect do
        broker.dynamic_destination('', exclusive: true)
      end.to_not raise_error
    end

    context 'when in a transaction' do
      it 'sets the channel_context as rollback-only until the transaction is finished' do
        MessageDriver::Client.with_message_transaction do
          expect do
            broker.dynamic_destination('not.a.queue', passive: true)
          end.to raise_error(MessageDriver::WrappedError)
          expect do
            broker.dynamic_destination('', exclusive: true)
          end.to raise_error(MessageDriver::TransactionRollbackOnly)
        end
        expect do
          broker.dynamic_destination('', exclusive: true)
        end.to_not raise_error
      end
    end
  end

  context 'when an unhandled expection occurs in a transaction' do
    let(:destination) { broker.dynamic_destination('', exclusive: true) }

    it 'rolls back the transaction' do
      expect do
        MessageDriver::Client.with_message_transaction do
          destination.publish('Test Message')
          fail 'unhandled error'
        end
      end.to raise_error 'unhandled error'
      expect(destination.pop_message).to be_nil
    end

    it 'allows the next transaction to continue' do
      expect do
        MessageDriver::Client.with_message_transaction do
          destination.publish('Test Message 1')
          fail 'unhandled error'
        end
      end.to raise_error 'unhandled error'
      expect(destination.pop_message).to be_nil

      MessageDriver::Client.with_message_transaction do
        destination.publish('Test Message 2')
      end

      msg = destination.pop_message
      expect(msg).to_not be_nil
      expect(msg.body).to eq('Test Message 2')
    end
  end
end
