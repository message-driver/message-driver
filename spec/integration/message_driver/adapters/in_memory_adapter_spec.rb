require 'spec_helper'

require 'message_driver/adapters/in_memory_adapter'

module MessageDriver::Adapters
  describe InMemoryAdapter, :in_memory, type: :integration do
    let(:adapter) { described_class.new }

    describe "#create_destination" do
      describe "the resulting destination" do
        let!(:destination) { adapter.create_destination("my_test_dest") }
        it_behaves_like "a destination"

        subject { destination }

        it { should be_a InMemoryAdapter::Destination }

        include_examples "supports #message_count"
      end

      context "when creating two destinations for the same queue" do
        it "creates seperate destination instances" do
          queue_name = "my_queue"
          dest1 = adapter.create_destination(queue_name)
          dest2 = adapter.create_destination(queue_name)
          expect(dest1).to_not be(dest2)
        end
      end
    end

    describe "#reset_after_tests" do
      it "empties all the destination queues" do
        destinations = (1..3).map(&adapter.method(:create_destination))
        destinations.each do |destination|
          destination.publish("There's always money in the banana stand!", {}, {})
        end

        adapter.reset_after_tests

        destinations.each do |destination|
          expect(destination.message_count).to eq(0)
        end
      end

      it "removes any existing subscriptions" do
        destinations = (1..3).map(&adapter.method(:create_destination))
        consumer = lambda do |m| end
        destinations.each do |destination|
          destination.subscribe(&consumer)
        end

        adapter.reset_after_tests

        destinations.each do |destination|
          expect(destination.consumer).to be_nil
        end

      end
    end

    describe "#subscribe" do
      let(:message1) { "message 1" }
      let(:message2) { "message 2" }
      let(:destination) { adapter.create_destination(:my_queue) }
      let(:messages) { [] }
      let(:consumer) do
        lambda do |msg|
          messages << msg
        end
      end

      it "sets the consumer on the destination" do
        adapter.subscribe(destination.name, &consumer)
        expect(destination.consumer).to be(consumer)
      end

      context "when there are already messages in the destination" do
        before do
          destination.publish(message1)
          destination.publish(message2)
        end

        it "plays the messages into the consumer" do
          adapter.subscribe(destination.name, &consumer)
          expect(messages).to have(2).items
          expect(messages[0].body).to eq(message1)
          expect(messages[1].body).to eq(message2)
        end

        it "removes the messages from the queue" do
          expect {
            adapter.subscribe(destination.name, &consumer)
          }.to change{destination.message_count}.from(2).to(0)
        end
      end

      context "when a message is published to the destination" do
        before do
          adapter.subscribe(destination.name, &consumer)
        end
        it "plays the messages into the consumer instead of putting them on the queue" do
          expect {
            expect {
              destination.publish(message1)
            }.to change{messages.length}.from(0).to(1)
          }.to_not change{destination.message_count}
          expect(messages[0].body).to eq(message1)
        end
      end
    end

    describe "accessing the same queue from two destinations" do
      let(:queue_name) { "my_queue" }
      let(:dest1) { adapter.create_destination(queue_name) }
      let(:dest2) { adapter.create_destination(queue_name) }

      context "when I have a consumer on one destination" do
        let(:consumer) { lambda do |m| end }
        before do
          dest1.subscribe(&consumer)
        end
        it "is the same consumer on the other destination" do
          expect(dest2.consumer).to be(consumer)
        end
      end

      context "when I publish a message to one destination" do
        it "changes the message_count on the other" do
          expect {
            dest1.publish("my test message")
          }.to change{dest2.message_count}.from(0).to(1)
        end

        it "can be popped off the other" do
          dest1.publish("my test message")
          msg = dest2.pop_message
          expect(msg).to_not be_nil
          expect(msg.body).to eq("my test message")
        end
      end

      context "when I pop a message off one destination" do
        let(:message_body) { "test popping a message" }
        before do
          dest2.publish(message_body)
        end

        it "changes the message_count on the other" do
          expect {
            dest1.pop_message
          }.to change{dest2.message_count}.from(1).to(0)
        end
      end
    end
  end
end
