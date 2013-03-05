shared_examples "an adapter" do
  let(:destination) { "shared_adapter_examples_queue" }
  describe "#pop_message" do
    let(:body) { "The message body" }
    let(:headers) { { "foo" => "bar", "bar" => "baz"} }
    let(:properties) { {persistent: true, client_ack: true} }

    before do
      adapter.send_message(destination, body, headers, properties)
    end

    context "the result" do
      let!(:message) { adapter.pop_message(destination) }
      subject { message }

      it { should be_a MessageDriver::Message::Base }
      its(:body) { should eq(body) }
      its(:headers) { should eq(headers) }
      its(:properties) { should_not be_nil }
    end
  end
end
