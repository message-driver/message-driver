require 'spec_helper'

module MessageDriver::Message
  describe Base do
    describe "#initialize" do
      let(:body) { "The message body" }
      let(:headers) { { foo: :bar, bar: :baz} }
      let(:properties) { {persistent: true, client_ack: true} }

      context "sets the body, header and properites on initialization" do
        subject { described_class.new(body, headers, properties) }

        its(:body) { should eq(body) }
        its(:headers) { should eq(headers) }
        its(:properties) { should eq(properties) }
      end
    end

    subject(:message) { described_class.new("body", {}, {}) }

    describe "#ack" do
      let(:options) { {foo: :bar} }

      before do
        MessageDriver::Client.stub(:ack_message)
      end
      it "passes itself to Client.ack_message" do
        subject.ack
        expect(MessageDriver::Client).to have_received(:ack_message).with(subject, {})
      end

      it "passes the options to Client.ack_message" do
        subject.ack(options)
        expect(MessageDriver::Client).to have_received(:ack_message).with(subject, options)
      end
    end

    describe "#nack" do
      let(:options) { {foo: :bar} }

      before do
        MessageDriver::Client.stub(:nack_message)
      end
      it "passes itself to Client.nack_message" do
        subject.nack
        expect(MessageDriver::Client).to have_received(:nack_message).with(subject, {})
      end

      it "passes the options to Client.nack_message" do
        subject.nack(options)
        expect(MessageDriver::Client).to have_received(:nack_message).with(subject, options)
      end
    end
  end
end
