module Utils
  def pause_if_needed(seconds=0.1)
    seconds *= 20 if ENV['TRAVIS'] == 'true'
    case BrokerConfig.current_adapter
    when :bunny
      puts "sleeping for #{seconds} seconds"
      sleep seconds
    end
  end
end

RSpec.configure do |config|
  config.include Utils
end
