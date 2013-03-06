shared_examples "a destination" do
  describe "#pop_message" do
    let(:body) { "The message body" }
    let(:headers) { { "foo" => "bar", "bar" => "baz"} }
    let(:properties) { {persistent: true, client_ack: true} }

    before do
      destination.send_message(body, headers, properties)
    end

    context "the result" do
      let!(:message) { destination.pop_message }
      subject { message }

      it { should be_a MessageDriver::Message::Base }
      its(:body) { should eq(body) }
      its(:headers) { should eq(headers) }
      its(:properties) { should_not be_nil }
    end
  end
end
