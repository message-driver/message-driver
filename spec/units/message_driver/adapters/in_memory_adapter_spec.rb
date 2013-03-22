require 'spec_helper'

require 'message_driver/adapters/in_memory_adapter'

module MessageDriver::Adapters
  describe InMemoryAdapter do
    let(:adapter) { described_class.new }

    describe "#create_destination" do
      describe "the resulting destination" do
        let!(:destination) { adapter.create_destination("my_test_dest") }
        it_behaves_like "a destination"

        subject { destination }

        it { should be_a InMemoryAdapter::Destination }

        include_examples "supports #message_count"
      end
    end

    describe "#reset_after_tests" do
      #make some destinations
      # throw some messages on it
      # assert the messages are in the destinations
      # empty the queues on each destination via method
      # assert destinations are empty

      it "empties all the destination queues" do
        destinations = (1..3).map(&adapter.method(:create_destination))
        destinations.each do |destination|
          destination.publish("There's always money in the banana stand!", {}, {})
        end

        adapter.reset_after_tests

        destinations.each do |destination|
          expect(destination.pop_message).to be_nil
        end
      end
    end
  end
end
