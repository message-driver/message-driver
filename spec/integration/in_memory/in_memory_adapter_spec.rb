require 'spec_helper'

require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  module Adapters
    describe InMemoryAdapter, :in_memory, type: :integration do
      let(:broker) { double(Broker) }
      subject(:adapter) { described_class.new(broker) }

      describe '#new_context' do
        it 'returns a InMemoryAdapter::InMemoryContext' do
          expect(subject.new_context).to be_a InMemoryAdapter::InMemoryContext
        end
      end

      it_behaves_like 'an adapter'

      describe 'InMemoryAdapter::InMemoryContext' do
        subject(:adapter_context) { adapter.new_context }

        it_behaves_like 'an adapter context'
        it_behaves_like 'transactions are not supported'
        it_behaves_like 'client acks are not supported'
        it_behaves_like 'subscriptions are supported', InMemoryAdapter::Subscription
      end

      describe '#create_destination' do
        describe 'the resulting destination' do
          subject(:destination) { adapter.create_destination('my_test_dest') }

          it { is_expected.to be_a InMemoryAdapter::Destination }

          it_behaves_like 'a destination'
          include_examples 'supports #message_count'
          include_examples 'supports #consumer_count'
        end

        context 'when creating two destinations for the same queue' do
          it 'creates seperate destination instances' do
            queue_name = 'my_queue'
            dest1 = adapter.create_destination(queue_name)
            dest2 = adapter.create_destination(queue_name)
            expect(dest1).to_not be(dest2)
          end
        end
      end

      describe '#reset_after_tests' do
        it 'empties all the destination queues' do
          destinations = (1..3).map(&adapter.method(:create_destination))
          destinations.each do |destination|
            destination.publish("There's always money in the banana stand!", {}, {})
          end

          adapter.reset_after_tests

          destinations.each do |destination|
            expect(destination.message_count).to eq(0)
          end
        end

        it 'removes any existing subscriptions' do
          destinations = (1..3).map(&adapter.method(:create_destination))
          consumer = ->(_) {}
          destinations.each do |destination|
            destination.subscribe(&consumer)
          end

          adapter.reset_after_tests

          destinations.each do |destination|
            expect(destination.subscription).to be_nil
          end

        end
      end

      describe 'accessing the same queue from two destinations' do
        let(:queue_name) { 'my_queue' }
        let(:dest1) { adapter.create_destination(queue_name) }
        let(:dest2) { adapter.create_destination(queue_name) }

        context 'when I have a consumer on one destination' do
          let(:consumer) { ->(_) {} }
          before do
            dest1.subscribe(&consumer)
          end
          it 'is the same consumer on the other destination' do
            expect(dest2.subscription.consumer).to be(consumer)
          end
        end

        context 'when I publish a message to one destination' do
          it 'changes the message_count on the other' do
            expect do
              dest1.publish('my test message')
            end.to change { dest2.message_count }.from(0).to(1)
          end

          it 'can be popped off the other' do
            dest1.publish('my test message')
            msg = dest2.pop_message
            expect(msg).to_not be_nil
            expect(msg.body).to eq('my test message')
          end
        end

        context 'when I pop a message off one destination' do
          let(:message_body) { 'test popping a message' }
          before do
            dest2.publish(message_body)
          end

          it 'changes the message_count on the other' do
            expect do
              dest1.pop_message
            end.to change { dest2.message_count }.from(1).to(0)
          end
        end
      end

      describe 'subscribing a consumer' do
        let(:destination) { adapter.create_destination(:my_queue) }

        let(:subscription_type) { MessageDriver::Adapters::InMemoryAdapter::Subscription }
      end
    end
  end
end
