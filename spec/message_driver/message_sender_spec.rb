require 'spec_helper'

describe MessageDriver::MessageSender do
  class TestSender
    include MessageDriver::MessageSender
  end

  let(:adapter) { MessageDriver::Adapter::InMemory.new }
  before do
    MessageDriver.configure(adapter: adapter)
  end

  subject { TestSender.new }

  describe "#send_message" do
    let(:destination) { "my_queue" }
    let(:body) { "my message body" }

    it "only requires destination and body" do
      adapter.should_receive(:send_message).with(destination, body, {}, {})

      subject.send_message(destination, body)
    end

    let(:headers) { {foo: :bar} }
    let(:properties) { {bar: :baz} }

    it "also passes through the headers and properties" do
      adapter.should_receive(:send_message).with(destination, body, headers, properties)

      subject.send_message(destination, body, headers, properties)
    end
  end
end
