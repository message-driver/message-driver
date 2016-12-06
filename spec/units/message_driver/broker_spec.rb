require 'spec_helper'
require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  RSpec.describe Broker do
    let(:broker_name) { described_class::DEFAULT_BROKER_NAME }
    let(:options) { { adapter: :in_memory } }

    describe '.configure and .broker' do
      it 'calls new, passing in the options and saves the instance' do
        options = { foo: :bar }
        result = double(described_class).as_null_object
        expect(described_class).to receive(:new).with(described_class::DEFAULT_BROKER_NAME, options).and_return(result)

        described_class.configure(options)

        expect(described_class.broker).to be result
        expect(described_class.broker(described_class::DEFAULT_BROKER_NAME)).to be result
      end

      it "doesn't allow you to configure the same broker twice" do
        described_class.configure(broker_name, options)
        expect do
          described_class.configure(broker_name, options)
        end.to raise_error MessageDriver::BrokerAlreadyConfigured, /default/
      end

      context 'when configurating multiple brokers' do
        it 'allows you to fetch each configured broker through .broker' do
          options1 = { foo: :bar }
          options2 = { bar: :baz }
          result1 = double('result1').as_null_object
          result2 = double('result2').as_null_object
          allow(described_class).to receive(:new).with(:result1, options1).and_return(result1)
          allow(described_class).to receive(:new).with(:result2, options2).and_return(result2)

          described_class.configure(:result1, options1)
          described_class.configure(:result2, options2)

          expect(described_class.broker(:result1)).to be(result1)
          expect(described_class.broker(:result2)).to be(result2)
        end
      end

      context "when you try to access a broker that isn't configured" do
        it 'should raise an error' do
          expect do
            described_class.broker(:not_an_adapter)
          end.to raise_error BrokerNotConfigured
        end
      end
    end

    describe '.reset' do
      it 'stops and removes all the brokers' do
        broker1 = described_class.configure(:broker1, adapter: :in_memory)
        broker2 = described_class.configure(:broker2, adapter: :in_memory)

        allow(broker1).to receive(:stop).and_call_original
        allow(broker2).to receive(:stop).and_call_original

        described_class.reset

        expect(broker1).to have_received(:stop)
        expect(broker2).to have_received(:stop)

        expect do
          described_class.broker(:broker1)
        end.to raise_error BrokerNotConfigured

        expect do
          described_class.broker(:broker2)
        end.to raise_error BrokerNotConfigured
      end

      context 'when one of the brokers raises and error' do
        it 'still stops all the brokers' do
          broker1 = described_class.configure(:broker1, adapter: :in_memory)
          broker2 = described_class.configure(:broker2, adapter: :in_memory)

          allow(broker1).to receive(:stop).and_raise 'error stopping broker1!'
          allow(broker2).to receive(:stop).and_call_original

          expect do
            described_class.reset
          end.not_to raise_error

          expect(broker1).to have_received(:stop)
          expect(broker2).to have_received(:stop)

          expect do
            described_class.broker(:broker1)
          end.to raise_error BrokerNotConfigured

          expect do
            described_class.broker(:broker2)
          end.to raise_error BrokerNotConfigured
        end
      end
    end

    describe '.client' do
      let(:broker_name) { described_class::DEFAULT_BROKER_NAME }
      it 'returns a module that extends MessageDriver::Client for the specified broker' do
        expect(described_class.client(broker_name)).to be_kind_of MessageDriver::Client
        expect(described_class.client(broker_name).broker_name).to eq(broker_name)
      end

      it 'caches the modules' do
        first = described_class.client(broker_name)
        second = described_class.client(broker_name)
        expect(second).to be first
      end

      context 'when the broker has a non-default name' do
        let(:broker_name) { :my_cool_broker }
        it "returns a module that extends MessageDriver::Client that knows it's broker" do
          expect(described_class.client(broker_name)).to be_kind_of MessageDriver::Client
          expect(described_class.client(broker_name).broker_name).to eq(broker_name)
        end
      end
    end

    describe '#initialize' do
      it "raises an error if you don't specify an adapter" do
        expect do
          described_class.new({})
        end.to raise_error(/must specify an adapter/)
      end

      it 'if you provide an adapter instance, it uses that one' do
        adapter = Adapters::InMemoryAdapter.new({})

        instance = described_class.new(adapter: adapter)
        expect(instance.adapter).to be adapter
      end

      it 'if you provide an adapter class, it will instansiate it' do
        adapter = Adapters::InMemoryAdapter

        instance = described_class.new(adapter: adapter)
        expect(instance.adapter).to be_a adapter
      end

      it 'if you provide a symbol, it will try to look up the adapter class' do
        adapter = :in_memory

        instance = described_class.new(adapter: adapter)
        expect(instance.adapter).to be_a Adapters::InMemoryAdapter
      end

      it "raises and error if you don't provide a MessageDriver::Adapters::Base" do
        adapter = {}

        expect do
          described_class.new(adapter: adapter)
        end.to raise_error(/adapter must be a MessageDriver::Adapters::Base/)
      end

      it 'starts off with the adapter not stopped' do
        adapter = :in_memory

        instance = described_class.new(adapter: adapter)
        expect(instance).not_to be_stopped
      end

      it 'has a default name of :default' do
        adapter = :in_memory

        instance = described_class.new(adapter: adapter)
        expect(instance.name).to eq(:default)
      end

      it "let's you override the name in the initializer" do
        adapter = :in_memory
        name = :my_vhost

        instance = described_class.new(name, adapter: adapter)
        expect(instance.name).to eq(name)
      end
    end

    context do
      subject!(:broker) { described_class.configure(broker_name, options) }

      describe '#stop' do
        let(:adapter) { broker.adapter }
        it 'calls stop on the adapter' do
          allow(adapter).to receive(:stop).and_call_original

          subject.stop

          expect(adapter).to have_received(:stop)
        end

        it 'marks the broker as stopped' do
          expect do
            subject.stop
          end.to change { subject.stopped? }.from(false).to(true)
        end

        it 'invalidates the contexts' do
          my_ctx = double('context', invalidate: nil)
          adapter.contexts << my_ctx
          subject.stop
          expect(adapter.contexts).to be_empty
          expect(my_ctx).to have_received(:invalidate)
        end
      end

      describe '#restart' do
        let!(:original_adapter) { subject.adapter }
        before do
          allow(original_adapter).to receive(:stop).and_call_original
        end

        it 'reconfigures the adapter' do
          expect do
            subject.restart
          end.to change { subject.adapter }
        end

        it "stops the adapter if it hasn't already been stopped" do
          subject.restart
          expect(original_adapter).to have_received(:stop).once
        end

        it 'does not stop the adapter again if it has already been stopped' do
          expect(subject.adapter).to be original_adapter
          subject.stop
          expect do
            subject.restart
          end.to change { subject.stopped? }.from(true).to(false)
          expect(original_adapter).to have_received(:stop).once
        end
      end

      describe '#configuration' do
        it 'returns the configuration hash you passed to .configure' do
          config = { adapter: :in_memory, foo: :bar, baz: :boz }
          instance = described_class.new(config)
          expect(instance.configuration).to be config
        end
      end

      describe '#destination' do
        it 'returns the destination' do
          destination = broker.destination(:my_queue, 'my_queue', exclusive: true)
          expect(destination).to be_a MessageDriver::Destination::Base
        end
      end

      describe '#find_destination' do
        it 'finds the previously defined destination' do
          my_destination = broker.destination(:my_queue, 'my_queue', exclusive: true)
          expect(broker.find_destination(:my_queue)).to be(my_destination)
        end

        context "when the destination can't be found" do
          let(:bad_dest_name) { :not_a_queue }
          it 'raises a MessageDriver:NoSuchDestinationError' do
            expect do
              broker.find_destination(bad_dest_name)
            end.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
          end
        end
      end

      describe '#consumer' do
        let(:consumer_double) { ->(_) {} }
        it 'saves the provided consumer' do
          broker.consumer(:my_consumer, &consumer_double)
          expect(broker.consumers[:my_consumer]).to be(consumer_double)
        end

        context 'when no consumer is provided' do
          it 'raises an error' do
            expect do
              broker.consumer(:my_consumer)
            end.to raise_error(MessageDriver::Error, 'you must provide a block')
          end
        end
      end

      describe '#find_consumer' do
        let(:consumer_double) { ->(_) {} }
        it 'finds the previously defined consumer' do
          my_consumer = broker.consumer(:my_consumer, &consumer_double)
          expect(broker.find_consumer(:my_consumer)).to be(my_consumer)
        end

        context "when the consumer can't be found" do
          let(:bad_consumer_name) { :not_a_queue }
          it 'raises a MessageDriver:NoSuchConsumerError' do
            expect do
              broker.find_consumer(bad_consumer_name)
            end.to raise_error(MessageDriver::NoSuchConsumerError, /#{bad_consumer_name}/)
          end
        end
      end

      describe '#dynamic_destination' do
        it 'returns the destination' do
          destination = broker.dynamic_destination('my_queue', exclusive: true)
          expect(destination).to be_a MessageDriver::Destination::Base
        end
      end

      describe '#client' do
        let(:broker_name) { described_class::DEFAULT_BROKER_NAME }
        it "returns a module that extends MessageDriver::Client that knows it's broker" do
          expect(broker.client).to be_kind_of MessageDriver::Client
          expect(broker.client.broker_name).to eq(broker_name)
          expect(broker.client.broker).to be(broker)
        end

        it 'caches the modules' do
          first = broker.client
          second = broker.client
          expect(second).to be first
        end

        it 'returns the same module as .client' do
          expect(broker.client).to be described_class.client(broker.name)
        end

        context 'when the broker has a non-default name' do
          let(:broker_name) { :my_cool_broker }
          it "returns a module that extends MessageDriver::Client that knows it's broker" do
            expect(broker.name).to eq(broker_name)
            expect(broker.client).to be_kind_of MessageDriver::Client
            expect(broker.client.broker_name).to eq(broker_name)
            expect(broker.client.broker).to be(broker)
          end
        end
      end
    end
  end
end
