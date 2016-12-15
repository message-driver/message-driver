RSpec.shared_examples 'a destination' do
  describe '#adapter' do
    it { expect(subject.adapter).to be adapter }
  end

  describe '#pop_message' do
    let(:body) { 'The message body' }
    let(:headers) { { 'foo' => 'bar', 'bar' => 'baz' } }
    let(:properties) { { persistent: true, client_ack: true } }

    before do
      destination.publish(body, headers, properties)
    end

    context 'the result' do
      subject(:message) { destination.pop_message }

      it { is_expected.to be_a MessageDriver::Message::Base }

      it 'has a reference to the context that fetched it' do
        expect(message.ctx).to be_a MessageDriver::Adapters::ContextBase
      end

      it 'has a reference to the destination that it was fetched from' do
        expect(message.destination).to be_a MessageDriver::Destination::Base
      end

      describe '#body' do
        it { expect(subject.body).to eq(body) }
      end

      describe '#headers' do
        it { expect(subject.headers).to include(headers) }
      end

      describe '#properties' do
        it { expect(subject.properties).not_to be_nil }
      end
    end
  end

  context 'interface' do
    it { is_expected.to respond_to(:publish).with(1..3).arguments }
    it { is_expected.to respond_to(:pop_message).with(0..1).arguments }
    it { is_expected.to respond_to(:message_count).with(0).arguments }
    it { is_expected.to respond_to(:subscribe).with(0..1).arguments }
    it { is_expected.to respond_to(:consumer_count).with(0).arguments }
  end
end

RSpec.shared_examples "doesn't support #message_count" do
  describe '#message_count' do
    it 'raises an error' do
      expect do
        destination.message_count
      end.to raise_error "#message_count is not supported by #{destination.class}"
    end
  end
end

RSpec.shared_examples 'supports #message_count' do
  it "reports it's message_count" do
    expect do
      destination.publish('msg1')
      destination.publish('msg2')
      pause_if_needed
    end.to change { destination.message_count }.by(2)
  end

  it { is_expected.not_to override_method :message_count }

  it 'the adapter context overrides #handle_message_count' do
    expect(subject.adapter.broker.client.current_adapter_context).to override_method :handle_message_count
  end
end

RSpec.shared_examples "doesn't support #consumer_count" do
  describe '#consumer_count' do
    it 'raises an error' do
      expect do
        destination.consumer_count
      end.to raise_error "#consumer_count is not supported by #{destination.class}"
    end
  end
end

RSpec.shared_examples 'supports #consumer_count' do
  describe '#consumer_count' do
    it "reports it's consumer count" do
      consumer1 = ->(_) {}
      consumer2 = ->(_) {}
      sub1 = nil
      sub2 = nil
      expect do
        sub1 = destination.subscribe(&consumer1)
        sub2 = destination.subscribe(&consumer2)
      end.to change { destination.consumer_count }.by(2)
      expect do
        sub1.unsubscribe
        sub2.unsubscribe
      end.to change { destination.consumer_count }.by(-2)
    end
  end

  it { is_expected.not_to override_method :consumer_count }

  it 'the adapter context overrides #handle_consumer_count' do
    expect(subject.adapter.broker.client.current_adapter_context).to override_method :handle_message_count
  end
end
