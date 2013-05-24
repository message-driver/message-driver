require 'spec_helper'

module MessageDriver::Subscription
  describe Base do
    let(:adapter) { stub(MessageDriver::Adapters::Base) }
    let(:destination) { stub(MessageDriver::Destination::Base) }
    let(:consumer) { stub("a consumer") }
    subject(:subscription) { Base.new(adapter, destination, consumer) }

    it "sets it's adapter, destination and consumer on instansiation" do
      expect(subscription.adapter).to eq(adapter)
      expect(subscription.destination).to eq(destination)
      expect(subscription.consumer).to eq(consumer)
    end

    describe "#unsubscribe" do
      it "raises an error" do
        expect {
          subscription.unsubscribe
        }.to raise_error("must be implemented in subclass")
      end
    end
  end
end
