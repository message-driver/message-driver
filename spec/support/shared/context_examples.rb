RSpec.shared_examples 'an adapter context' do
  it { is_expected.to be_a MessageDriver::Adapters::ContextBase }

  describe '#adapter' do
    it { expect(subject.adapter).to be adapter }
  end

  it 'is initially valid' do
    is_expected.to be_valid
  end

  describe '#invalidate' do
    it 'causes the context to become invalid' do
      subject.invalidate
      expect(subject).to_not be_valid
    end
  end
end
