require 'spec_helper'

module MessageDriver
  module Destination
    RSpec.describe Base do
      subject(:destination) { Base.new(nil, nil, nil, nil) }

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
          end.to raise_error "#subscribe is not supported by #{destination.class}"
        end
      end
    end
  end
end
