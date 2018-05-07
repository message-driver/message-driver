source 'https://rubygems.org'

# Specify your gem's dependencies in message-driver.gemspec
gemspec

group :tools do
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'guard-rubocop'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  group :darwin do
    gem 'ruby_gntp'
    gem 'rb-fsevent'
    gem 'relish'
    gem 'lunchy'
  end
  gem 'yard'
  gem 'redcarpet'
  gem 'launchy'
end

group :development do
  gem 'thread_safe' # for the in_memory_adapter
  gem 'coveralls', require: false
end

require File.expand_path('../test_lib/broker_config', __FILE__)

adapter = BrokerConfig.current_adapter.to_s
version = BrokerConfig.adapter_version
provider = BrokerConfig.provider

group :development do
  unless adapter == 'in_memory'
    case version
    when nil
      gem adapter
    else
      gem adapter.to_s, "~> #{version}"
    end
  end

  case provider
  when :rabbitmq
    gem 'rabbitmq_http_api_client'
  end
end
