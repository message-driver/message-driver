require 'spec_helper'

describe MessageDriver::MessageReceiver do
  class TestReceiver
    include MessageDriver::MessageReceiver
  end

  let(:adapter) { MessageDriver::Adapter::InMemory.new }
  before do
    MessageDriver.configure(adapter: adapter)
  end

  subject { TestReceiver.new }

  describe "#pop_message" do
    let(:destination) { "my_queue" }
    let(:expected) { stub(MessageDriver::Message) }

    it "requires the destination and returns the message" do
      adapter.should_receive(:pop_message).with(destination, {}).and_return(expected)

      actual = subject.pop_message(destination)

      expect(actual).to be expected
    end

    let(:options) { {foo: :bar} }

    it "passes the options through and returns the message" do
      adapter.should_receive(:pop_message).with(destination, options).and_return(expected)

      actual = subject.pop_message(destination, options)

      expect(actual).to be expected
    end
  end
end
