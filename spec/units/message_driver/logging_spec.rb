require 'spec_helper'

module MessageDriver
  describe Logging do
    class TestLogger
      include Logging
    end
    subject { TestLogger.new }

    describe "#logger" do
      let(:logger) { double(Logger) }
      it "returns the broker logger" do
        allow(MessageDriver::Broker).to receive(:logger).and_return(logger)
        expect(subject.logger).to be logger
      end
    end
  end
end
