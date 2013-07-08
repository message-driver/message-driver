require 'spec_helper'

module MessageDriver::Adapters
  describe Base do
    class TestAdapter < described_class
      def initialize(configuration)

      end
    end
    subject { TestAdapter.new({}) }

    describe "#new_context" do
      it "raises an error", pending: "eventual behavior" do
        expect {
          subject.new_context
        }.to raise_error "Must be implemented in subclass"
      end
    end

    describe "#stop", pending: "maybe we don't want to do this" do
      it "raises an error" do
        expect {
          subject.stop
        }.to raise_error "Must be implemented in subclass"
      end
    end
  end

  describe ContextBase do
    class TestContext < described_class
    end
    subject { TestContext.new }

    describe "#with_transaction" do
      it "raises an error", pending: "eventual behavior" do
        expect {
          subject.with_transaction
        }.to raise_error "Must be implemented in subclass"
      end
    end

    describe "#create_destination" do
      it "raises an error", pending: "eventual behavior" do
        expect {
          subject.create_destination("foo")
        }.to raise_error "Must be implemented in subclass"
      end
    end

    describe "#publish" do
      it "raises an error", pending: "eventual behavior" do
        expect {
          subject.publish(:destination, {foo: "bar"})
        }.to raise_error "Must be implemented in subclass"
      end
    end

    describe "#pop_message" do
      it "raises an error", pending: "eventual behavior" do
        expect {
          subject.pop_message(:destination)
        }.to raise_error "Must be implemented in subclass"
      end
    end

    describe "#subscribe" do
      it "raises an error", pending: "eventual behavior" do
        expect {
          subject.subscribe(:destination, :consumer)
        }.to raise_error "Must be implemented in subclass"
      end
    end

  end
end
