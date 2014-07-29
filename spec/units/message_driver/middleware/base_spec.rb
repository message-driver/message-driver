require 'spec_helper'

module MessageDriver
  module Middleware
    RSpec.describe Base do
      let(:destination) { double(Destination) }
      subject(:middleware_base) { described_class.new(destination) }

      let(:body) { double('body') }
      let(:headers) { double('headers') }
      let(:properties) { double('properties') }

      describe '#destination' do
        it { expect(subject.destination).to be destination }
      end

      describe '#on_publish' do
        it 'just returns the input values' do
          expect(subject.on_publish(body, headers, properties)).to eq [body, headers, properties]
        end
      end

      describe '#on_consume' do
        it 'just returns the input values' do
          expect(subject.on_consume(body, headers, properties)).to eq [body, headers, properties]
        end
      end
    end
  end
end
