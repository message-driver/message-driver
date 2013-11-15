module MessageDriver
  module Logging
    def logger
      MessageDriver::Broker.logger
    end

    def exception_to_str(e)
      (["#{e.class}: #{e.to_s}"] + e.backtrace).join("  \n")
    end
  end
end
