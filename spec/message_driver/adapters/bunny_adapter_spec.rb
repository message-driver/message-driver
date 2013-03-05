require 'spec_helper'

require 'message_driver/adapters/bunny_adapter'

module MessageDriver::Adapters
  describe BunnyAdapter, :pending do
    let(:adapter) { described_class.new }
    it_behaves_like "an adapter"

    describe "#initialize" do
      context "bunny verion 0.8.0" do
        it "raises an error" do
          stub_const("Bunny::VERSION", "0.8.0")
          expect {
            described_class.new({})
          }.to raise_error "bunny 0.9.0pre7 or later is required for the bunny adapter"
        end
      end
    end
  end
end
