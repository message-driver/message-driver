shared_examples "a destination" do
  describe "#pop_message" do
    let(:body) { "The message body" }
    let(:headers) { { "foo" => "bar", "bar" => "baz"} }
    let(:properties) { {persistent: true, client_ack: true} }

    before do
      destination.publish(body, headers, properties)
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

shared_examples "doesn't support #message_count" do
  describe "#message_count" do
    it "raises an error" do
      expect {
        destination.message_count
      }.to raise_error "#message_count is not supported by #{destination.class}"
    end
  end
end

shared_examples "supports #message_count" do
  #FIXME this example fails on travis with the bunny adapter :(
  it "reports it's message_count", :no_travis do
    expect {
      destination.publish("msg1")
      destination.publish("msg2")
    }.to change{destination.message_count}.by(2)
  end
end
