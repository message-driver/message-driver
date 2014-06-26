module MessageDriver
  module Logging
    extend self

    def logger
      MessageDriver.logger
    end

    def exception_to_str(e)
      (["#{e.class}: #{e}"] + e.backtrace).join("\n  ")
    end

    def message_with_exception(message, e)
      [message, exception_to_str(e)].join("\n")
    end
  end
end
