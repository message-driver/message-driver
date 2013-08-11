source 'https://rubygems.org'

# Specify your gem's dependencies in message-driver.gemspec
gemspec

group :tools do
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'pry'
  platform :ruby do
    gem 'pry-debugger'
  end
  group :darwin do
    gem 'ruby_gntp'
    gem 'rb-fsevent'
    gem 'relish'
  end
end

require File.expand_path("../test_lib/broker_config", __FILE__)

adapter = BrokerConfig.current_adapter
version = BrokerConfig.adapter_version

case adapter
when :in_memory
else
  gem adapter.to_s, version
end
