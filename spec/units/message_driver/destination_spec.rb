require 'spec_helper'

module MessageDriver
  module Destination
    describe Base do
      subject(:destination) { Base.new(nil, nil, nil, nil) }

      it 'needs some real tests'

      include_examples "doesn't support #message_count"

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
