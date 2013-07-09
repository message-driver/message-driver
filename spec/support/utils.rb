module Utils
  def pause_if_needed(seconds=0.1)
    case BrokerConfig.current_adapter
    when :bunny
      sleep seconds
    end
  end
end

RSpec.configure do |config|
  config.include Utils
end
