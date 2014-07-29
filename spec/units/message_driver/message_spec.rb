require 'spec_helper'

module MessageDriver
  module Message
    RSpec.describe Base do
      describe '#initialize' do
        let(:body) { 'The message body' }
        let(:headers) { { foo: :bar, bar: :baz } }
        let(:properties) { { persistent: true, client_ack: true } }
        let(:ctx) { double('adapter_context') }

        context 'sets the body, header and properites on initialization' do
          subject { described_class.new(ctx, body, headers, properties) }

          describe '#ctx' do
            it { expect(subject.ctx).to be(ctx) }
          end

          describe '#body' do
            it { expect(subject.body).to eq(body) }
          end

          describe '#headers' do
            it { expect(subject.headers).to eq(headers) }
          end

          describe '#properties' do
            it { expect(subject.properties).to eq(properties) }
          end

          describe '#raw_body' do
            it 'defaults to the body' do
              expect(subject.raw_body).to eq(subject.body)
            end

            it 'can be provided in the constructor' do
              msg = described_class.new(ctx, body, headers, properties, 'my_raw_body')

              expect(msg.raw_body).to eq('my_raw_body')
              expect(msg.body).to eq(body)
            end
          end
        end
      end

      let(:logger) { MessageDriver.logger }
      let(:ctx) { double('adapter_context') }
      let(:options) { double('options') }
      subject(:message) { described_class.new(ctx, 'body', {}, {}) }

      describe '#ack' do
        before do
          allow(ctx).to receive(:ack_message)
        end
        context 'when the adapter supports client acks' do
          before do
            allow(ctx).to receive(:supports_client_acks?) { true }
          end
          it 'calls #ack_message with the message' do
            subject.ack
            expect(ctx).to have_received(:ack_message).with(subject, {})
          end
          it 'passes the supplied options to ack_message' do
            subject.ack(options)
            expect(ctx).to have_received(:ack_message).with(subject, options)
          end
        end
        context "when the adapter doesn't support client acks" do
          before do
            allow(ctx).to receive(:supports_client_acks?) { false }
          end
          it "doesn't call #ack_message" do
            subject.ack
            expect(ctx).not_to have_received(:ack_message)
          end
          it 'logs a warning' do
            allow(logger).to receive(:debug)
            subject.ack
            expect(logger).to have_received(:debug).with('this adapter does not support client acks')
          end
        end
      end

      describe '#nack' do
        before do
          allow(ctx).to receive(:nack_message)
        end
        context 'when the adapter supports client nacks' do
          before do
            allow(ctx).to receive(:supports_client_acks?) { true }
          end
          it 'calls #nack_message with the message' do
            subject.nack
            expect(ctx).to have_received(:nack_message).with(subject, {})
          end
          it 'passes the supplied options to nack_message' do
            subject.nack(options)
            expect(ctx).to have_received(:nack_message).with(subject, options)
          end
        end
        context "when the adapter doesn't support client nacks" do
          before do
            allow(ctx).to receive(:supports_client_acks?) { false }
          end
          it "doesn't call #nack_message" do
            subject.nack
            expect(ctx).not_to have_received(:nack_message)
          end
          it 'logs a warning' do
            allow(logger).to receive(:debug)
            subject.nack
            expect(logger).to have_received(:debug).with('this adapter does not support client acks')
          end
        end
      end
    end
  end
end
