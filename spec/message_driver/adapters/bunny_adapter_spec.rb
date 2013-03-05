require 'spec_helper'

require 'message_driver/adapters/bunny_adapter'

module MessageDriver::Adapters
  describe BunnyAdapter, :bunny, :integration do
    pending do
      let(:adapter) { described_class.new({}) }
      it_behaves_like "an adapter"
    end

    describe "#initialize" do
      context "differing bunny versions" do
        shared_examples "raises an error" do
          it "raises an error" do
            stub_const("Bunny::VERSION", version)
            expect {
              described_class.new({})
            }.to raise_error "bunny 0.9.0.pre7 or later is required for the bunny adapter"
          end
        end
        shared_examples "doesn't raise an error" do
          it "doesn't raise an an error" do
            stub_const("Bunny::VERSION", version)
            expect {
              described_class.new({})
            }.to_not raise_error
          end
        end
        %w(0.8.0 0.9.0.pre6).each do |v|
          context "bunny version #{v}" do
            let(:version) { v }
            include_examples "raises an error"
          end
        end
        %w(0.9.0.pre7 0.9.0.rc1 0.9.0 0.9.1).each do |v|
          context "bunny version #{v}" do
            let(:version) { v }
            include_examples "doesn't raise an error"
          end
        end
      end

      it "connects to the rabbit broker" do
        adapter = described_class.new({})

        expect(adapter.connection).to be_a Bunny::Session
      end
    end
  end
end
