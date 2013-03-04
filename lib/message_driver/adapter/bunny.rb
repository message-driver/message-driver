module MessageDriver
  class Broker
    def self.bunny_adapter
      MessageDriver::Adapter::Bunny
    end
  end

  module Adapter
    class Bunny < Base

    end
  end
end
