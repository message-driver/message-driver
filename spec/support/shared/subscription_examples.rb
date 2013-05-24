shared_examples "subscription is supported" do

  it "sets the consumer on the destination" do
    adapter.subscribe(destination.name, &consumer)
    expect(destination.consumer).to be(consumer)
  end

  context "the result" do
    let(:destination) { adapter.create_destination(:my_queue) }
    let(:consumer) { lambda do |msg| end }

    subject(:subscription) { destination.subscribe(&consumer) }

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
    end
  end

end
