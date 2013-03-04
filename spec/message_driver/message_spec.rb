require 'spec_helper'

describe MessageDriver::Message::Base do
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
end
