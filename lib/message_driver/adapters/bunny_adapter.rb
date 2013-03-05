require 'bunny'

module MessageDriver
  class Broker
    def self.bunny_adapter
      MessageDriver::Adapters::BunnyAdapter
    end
  end

  module Adapters
    class BunnyAdapter < Base
      def initialize(config)
        validate_bunny_version

      end

      private

      def validate_bunny_version
        required = Gem::Requirement.create('>= 0.9.0pre7')
        current = Gem::Requirement.create(Bunny::VERSION)
        unless required.satisfied_by? current
          raise "bunny 0.9.0pre7 or later is required for the bunny adapter"
        end
      end
    end
  end
end
