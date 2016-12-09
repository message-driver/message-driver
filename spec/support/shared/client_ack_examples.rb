RSpec.shared_examples 'client acks are supported' do
  describe '#supports_client_acks?' do
    it 'returns true' do
      expect(subject.supports_client_acks?).to eq(true)
    end
  end

  it { is_expected.to override_method :handle_ack_message }
  it { is_expected.not_to override_method :ack_message }
  it { is_expected.to override_method :handle_nack_message }
  it { is_expected.not_to override_method :nack_message }
end

RSpec.shared_examples 'client acks are not supported' do
  it { is_expected.not_to override_method :handle_ack_message }
  it { is_expected.not_to override_method :handle_nack_message }
  describe '#supports_client_acks?' do
    it 'returns false' do
      expect(subject.supports_client_acks?).to eq(false)
    end
  end

  describe '#ack_message' do
    it 'raises an error' do
      message = double('message')
      expect do
        subject.ack_message(message)
      end.to raise_error "#ack_message is not supported by #{subject.adapter.class}"
    end
  end

  describe '#nack_message' do
    it 'raises an error' do
      message = double('message')
      expect do
        subject.nack_message(message)
      end.to raise_error "#nack_message is not supported by #{subject.adapter.class}"
    end
  end
end
