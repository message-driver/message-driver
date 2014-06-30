source 'https://rubygems.org'

# Specify your gem's dependencies in message-driver.gemspec
gemspec

platform :rbx do
  gem 'rubysl'
end

group :tools do
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'guard-rubocop'
  gem 'pry'
  gem 'pry-byebug', platform: [:mri_20, :mri_21]
  group :darwin do
    gem 'ruby_gntp'
    gem 'rb-fsevent'
    gem 'relish'
    gem 'lunchy'
  end
  gem 'yard'
  gem 'redcarpet'
  gem 'launchy'
end if RUBY_VERSION >= '1.9.3'

require File.expand_path('../test_lib/broker_config', __FILE__)

adapter = BrokerConfig.current_adapter.to_s
version = BrokerConfig.adapter_version

case adapter
when 'in_memory'
else
  case version
  when nil
    gem adapter
  else
    gem adapter.to_s, "~> #{version}"
  end
end
