require 'spec_helper'

module MessageDriver::Adapters
  describe Base do
    class TestAdapter < described_class
      def initialize(configuration)

      end
    end
    subject { TestAdapter.new({}) }

    describe "#send_message" do
      it "raises an error" do
        expect {
          subject.send_message(:destination, {foo: "bar"})
        }.to raise_error "Must be implemented in subclass"
      end
    end

    describe "#pop_message" do
      it "raises an error" do
        expect {
          subject.pop_message(:destination)
        }.to raise_error "Must be implemented in subclass"
      end
    end
  end
end
