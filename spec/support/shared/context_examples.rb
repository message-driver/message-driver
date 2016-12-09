RSpec.shared_examples 'an adapter context' do
  it { is_expected.to be_a MessageDriver::Adapters::ContextBase }

  describe '#adapter' do
    it { expect(subject.adapter).to be adapter }
  end

  describe 'interface' do
    it { is_expected.to respond_to(:create_destination).with(1..3).arguments }
    it { is_expected.to respond_to(:handle_create_destination).with(1..3).arguments }

    it { is_expected.to respond_to(:publish).with(2..4).arguments }
    it { is_expected.to respond_to(:handle_publish).with(2..4).arguments }

    it { is_expected.to respond_to(:pop_message).with(1..2).arguments }
    it { is_expected.to respond_to(:handle_pop_message).with(1..2).arguments }

    it { is_expected.to respond_to(:subscribe).with(1..2).arguments }
    it { is_expected.to respond_to(:handle_subscribe).with(1..2).arguments }

    it { is_expected.to respond_to(:ack_message).with(1..2).arguments }
    it { is_expected.to respond_to(:handle_ack_message).with(1..2).arguments }
    it { is_expected.to respond_to(:nack_message).with(1..2).arguments }
    it { is_expected.to respond_to(:handle_nack_message).with(1..2).arguments }

    it { is_expected.to respond_to(:begin_transaction).with(0..1).arguments }
    it { is_expected.to respond_to(:handle_begin_transaction).with(0..1).arguments }
    it { is_expected.to respond_to(:commit_transaction).with(0..1).arguments }
    it { is_expected.to respond_to(:handle_commit_transaction).with(0..1).arguments }
    it { is_expected.to respond_to(:rollback_transaction).with(0..1).arguments }
    it { is_expected.to respond_to(:handle_rollback_transaction).with(0..1).arguments }
    it { is_expected.to respond_to(:in_transaction?).with(0).arguments }

    it { is_expected.to respond_to(:message_count).with(1).arguments }
    it { is_expected.to respond_to(:handle_message_count).with(1).arguments }
    it { is_expected.to respond_to(:consumer_count).with(1).arguments }
    it { is_expected.to respond_to(:handle_consumer_count).with(1).arguments }

    describe 'overrides' do
      it { expect(subject.class).not_to override_method(:create_destination) }
      it { expect(subject.class).to override_method(:handle_create_destination) }

      it { expect(subject.class).not_to override_method(:publish) }
      it { expect(subject.class).to override_method(:handle_publish) }

      it { expect(subject.class).not_to override_method(:pop_message) }
      it { expect(subject.class).to override_method(:handle_pop_message) }

      it { expect(subject.class).not_to override_method(:message_count) }
      it { expect(subject.class).not_to override_method(:consumer_count) }
    end
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
