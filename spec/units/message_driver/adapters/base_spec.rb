require 'spec_helper'

module MessageDriver::Adapters
  describe Base do
    class TestAdapter < Base
      def initialize(configuration)
      end
    end
    subject(:adapter) { TestAdapter.new({}) }

    describe "#new_context" do
      it "raises an error" do
        expect {
          subject.new_context
        }.to raise_error "Must be implemented in subclass"
      end
    end

    describe "#stop" do
      it "raises an error", pending: "maybe we don't want to do this" do
        expect {
          subject.stop
        }.to raise_error "Must be implemented in subclass"
      end
      it "marks the adapter contexts as being invalid"
    end

    describe ContextBase do
      class TestContext < ContextBase
      end
      subject(:adapter_context) { TestContext.new(adapter) }

      include_examples "doesn't support transactions"

      describe "#create_destination" do
        it "raises an error" do
          expect {
            subject.create_destination("foo")
          }.to raise_error "Must be implemented in subclass"
        end
      end

      describe "#publish" do
        it "raises an error" do
          expect {
            subject.publish(:destination, {foo: "bar"})
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

      describe "#subscribe" do
        it "raises an error" do
          expect {
            subject.subscribe(:destination, :consumer)
          }.to raise_error "Must be implemented in subclass"
        end
      end

    end
  end
end
