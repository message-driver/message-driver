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
      end
    end
  end
end
