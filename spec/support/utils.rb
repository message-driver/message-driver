module Utils
  def pause_if_needed(seconds = 0.1)
    seconds *= 10 if ENV['CI'] == 'true'
    case BrokerConfig.current_adapter
    when :in_memory
    else
      sleep seconds
    end
  end
end

RSpec.configure do |config|
  config.include Utils
end
