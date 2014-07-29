require 'spec_helper'

module MessageDriver
  module Middleware
    RSpec.describe MiddlewareStack do
      class Top < Base; end
      class Middle < Base; end
      class Bottom < Base; end

      let(:top) { Top.new(destination) }
      let(:middle) { Middle.new(destination) }
      let(:bottom) { Bottom.new(destination) }

      before do
        allow(Top).to receive(:new).with(destination).and_return(top)
        allow(Middle).to receive(:new).with(destination).and_return(middle)
        allow(Bottom).to receive(:new).with(destination).and_return(bottom)
      end

      def load_middleware_doubles
        subject.append Middle
        subject.prepend Bottom
        subject.append Top
      end

      let(:destination) { double(Destination) }
      subject(:middleware_stack) { described_class.new(destination) }

      it { is_expected.to be_an Enumerable }

      describe '#destination' do
        it { expect(subject.destination).to be destination }
      end

      describe '#middlewares' do
        it 'is initially empty' do
          expect(subject.middlewares).to be_an Array
          expect(subject.middlewares).to be_empty
        end

        it 'returns the list of middlewares' do
          load_middleware_doubles
          expect(subject.middlewares).to eq [bottom, middle, top]
        end

        it 'ensures the returned list of middlewares is frozen' do
          expect(subject.middlewares).to be_frozen
        end
      end

      shared_examples 'a middleware builder' do |op|
        it 'instantiates the middleware and passes the destination to it' do
          allow(Top).to receive(:new).and_call_original
          subject.public_send op, Top
          middleware = subject.middlewares.first
          expect(middleware).to be_an_instance_of Top
          expect(middleware.destination).to be destination
        end

        it 'returns the instantiated middleware' do
          expect(subject.public_send(op, Top)).to be top
        end
      end

      describe '#append' do
        it 'adds middlewares to the top of the middleware stack' do
          subject.append Bottom
          subject.append Middle
          subject.append Top
          expect(subject.middlewares).to eq [bottom, middle, top]
        end

        it_behaves_like 'a middleware builder', :append
      end

      describe '#prepend' do
        it 'adds middlewares to the bottom of the middleware stack' do
          subject.prepend Top
          subject.prepend Middle
          subject.prepend Bottom
          expect(subject.middlewares).to eq [bottom, middle, top]
        end

        it_behaves_like 'a middleware builder', :prepend
      end

      describe '#on_publish' do
        it 'passes the message data to each middleware\'s #on_publish message, bottom to top' do
          load_middleware_doubles
          expect(subject.middlewares).to eq [bottom, middle, top]

          allow(bottom).to receive(:on_publish).and_call_original
          allow(middle).to receive(:on_publish).and_call_original
          allow(top).to receive(:on_publish).and_call_original

          body = double('body')
          headers = double('headers')
          properties = double('properties')

          expect(subject.on_publish(body, headers, properties)).to eq [body, headers, properties]

          expect(bottom).to have_received(:on_publish).ordered
          expect(middle).to have_received(:on_publish).ordered
          expect(top).to have_received(:on_publish).ordered
        end
      end

      describe '#on_consume' do
        it 'passes the message data to each middleware\'s #on_consume message, top to bottom' do
          load_middleware_doubles
          expect(subject.middlewares).to eq [bottom, middle, top]

          allow(bottom).to receive(:on_consume).and_call_original
          allow(middle).to receive(:on_consume).and_call_original
          allow(top).to receive(:on_consume).and_call_original

          body = double('body')
          headers = double('headers')
          properties = double('properties')

          expect(subject.on_consume(body, headers, properties)).to eq [body, headers, properties]

          expect(top).to have_received(:on_consume).ordered
          expect(middle).to have_received(:on_consume).ordered
          expect(bottom).to have_received(:on_consume).ordered
        end
      end
    end
  end
end
