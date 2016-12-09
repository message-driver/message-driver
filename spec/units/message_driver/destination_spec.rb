require 'spec_helper'

module MessageDriver
  module Destination
    RSpec.describe Base do
      let(:broker) { Broker.configure(:test, adapter: TestAdapter) }
      let(:adapter) { broker.adapter }
      subject(:destination) { Base.new(adapter, nil, nil, nil) }

      describe '#middlware' do
        it { expect(subject.middleware).to be_a Middleware::MiddlewareStack }
      end

      include_examples "doesn't support #message_count"
      include_examples "doesn't support #consumer_count"

      describe '#subscribe' do
        it 'raises an error' do
          expect do
            consumer = ->(_) {}
            destination.subscribe(&consumer)
          end.to raise_error "#subscribe is not supported by #{TestAdapter}"
        end
      end
    end
  end
end
