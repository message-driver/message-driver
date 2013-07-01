shared_examples "subscription is supported" do

  let(:message1) { "message 1" }
  let(:message2) { "message 2" }
  let(:messages) { [] }
  let(:consumer) do
    lambda do |msg|
      messages << msg
    end
  end

  let(:subscription) { destination.subscribe(&consumer) }
  after do
    subscription.unsubscribe
  end

  it "sets the consumer on the destination" do
    subscription
    expect(destination.consumer).to be(consumer)
  end

  context "when there are already messages in the destination" do
    before do
      destination.publish(message1)
      destination.publish(message2)
    end

    it "plays the messages into the consumer" do
      subscription
      sleep 0.1
      expect(messages).to have(2).items
      expect(messages[0].body).to eq(message1)
      expect(messages[1].body).to eq(message2)
    end

    it "removes the messages from the queue" do
      expect {
        subscription
      }.to change{destination.message_count}.from(2).to(0)
    end
  end

  context "when a message is published to the destination" do
    before do
      subscription
    end

    it "consumers the message into the consumer instead of putting them on the queue" do
      expect {
        expect {
          destination.publish(message1)
          sleep 0.1
        }.to change{messages.length}.from(0).to(1)
      }.to_not change{destination.message_count}
      expect(messages[0].body).to eq(message1)
    end
  end

  context "the result" do
    let(:destination) { adapter.create_destination(:my_queue) }

    subject { subscription }

    it { should be_a MessageDriver::Subscription::Base }
    it { should be_a subscription_type }
    its(:adapter) { should be adapter }
    its(:destination) { should be destination }
    its(:consumer) { should be consumer }

    describe "#unsubscribe" do
      it "unsets the consumer on the destination" do
        subscription.unsubscribe
        expect(destination.consumer).to be_nil
      end
      it "makes it so messages don't go to the consumer any more" do
        subscription.unsubscribe
        expect {
          destination.publish("should not be consumed")
        }.to_not change{messages.size}
      end
    end
  end
end

shared_examples "doesn't support #subscribe" do
  describe "#subscribe" do
    it "raises an error" do
      expect {
        consumer = lambda do |m| end
        destination.subscribe(&consumer)
      }.to raise_error "#subscribe is not supported by #{destination.class}"
    end
  end
end
