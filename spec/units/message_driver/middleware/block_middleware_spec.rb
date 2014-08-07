require 'spec_helper'

module MessageDriver
  module Middleware
    RSpec.describe BlockMiddleware do
      let(:destination) { double(Destination) }
      let(:a_block) { ->(b, h, p) { [b, h, p] } }
      describe '#initialize' do
        it 'requires you provide either an on_publish, or on_consume block' do
          expect do
            BlockMiddleware.new(destination, {})
          end.to raise_error(ArgumentError)
          expect do
            BlockMiddleware.new(destination, foo: a_block)
          end.to raise_error(ArgumentError)
          expect do
            BlockMiddleware.new(destination, on_publish: a_block)
          end.not_to raise_error
          expect do
            BlockMiddleware.new(destination, on_consume: a_block)
          end.not_to raise_error
          expect do
            BlockMiddleware.new(destination, on_consume: a_block, on_publish: a_block)
          end.not_to raise_error
        end

        it 'saves the provided blocks' do
          middleware = BlockMiddleware.new(destination, on_publish: a_block)
          expect(middleware.on_publish_block).to be(a_block)
          expect(middleware.on_consume_block).to be_nil

          middleware = BlockMiddleware.new(destination, on_consume: a_block)
          expect(middleware.on_publish_block).to be_nil
          expect(middleware.on_consume_block).to be(a_block)

          middleware = BlockMiddleware.new(destination, on_publish: a_block, on_consume: a_block)
          expect(middleware.on_publish_block).to be(a_block)
          expect(middleware.on_consume_block).to be(a_block)
        end
      end

      shared_context 'a message processor' do |op|
        let(:a_block) { double('a_block') }
        let(:subject) { described_class.new(destination, op => a_block) }

        let(:body) { double('body') }
        let(:headers) { double('headers') }
        let(:properties) { double('properties') }

        let(:result_body) { double('result_body') }
        let(:result_headers) { double('result_headers') }
        let(:result_properties) { double('result_properties') }

        before do
          allow(a_block).to receive(:call).and_return([result_body, result_headers, result_properties]) unless a_block.nil?
        end

        it 'delegates to the provided block and returns it\'s result' do
          result = subject.public_send(op, body, headers, properties)
          expect(a_block).to have_received(:call).with(body, headers, properties)
          expect(result).to eq([result_body, result_headers, result_properties])
        end

        context "when :#{op} was not provided" do
          let(:a_block) { nil }
          it 'just returns the original inputs' do
            result = subject.public_send(op, body, headers, properties)
            expect(result).to eq([body, headers, properties])
          end
        end
      end

      describe '#on_publish' do
        it_behaves_like 'a message processor', :on_publish
      end

      describe '#on_consume' do
        it_behaves_like 'a message processor', :on_consume
      end
    end
  end
end
