module Utils
  def pause_if_needed(seconds = 0.1)
    seconds *= 10 if ENV['CI'] == 'true'
    sleep seconds unless BrokerConfig.current_adapter == :in_memory
  end
end

RSpec.configure do |config|
  config.include Utils
end
