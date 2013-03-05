require 'bunny'

module MessageDriver
  class Broker
    def self.bunny_adapter
      MessageDriver::Adapters::BunnyAdapter
    end
  end

  module Adapters
    class BunnyAdapter < Base
      attr_reader :connection

      def initialize(config)
        validate_bunny_version

        @connection = Bunny.new(config)
      end

      private

      def validate_bunny_version
        required = Gem::Requirement.create('~> 0.9.0.pre7')
        current = Gem::Version.create(Bunny::VERSION)
        unless required.satisfied_by? current
          raise "bunny 0.9.0.pre7 or later is required for the bunny adapter"
        end
      end
    end
  end
end
