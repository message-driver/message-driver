shared_examples "supports client acks" do
  describe "#supports_client_acks" do
    it "returns true" do
      expect(subject.supports_client_acks?).to eq(true)
    end
  end

  it { should respond_to :ack_message }
  it { should respond_to :nack_message }
end

shared_examples "doesn't support client acks" do
  describe "#supports_client_acks" do
    it "returns false" do
      expect(subject.supports_client_acks?).to eq(false)
    end
  end
end
