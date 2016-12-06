source 'https://rubygems.org'

# Specify your gem's dependencies in message-driver.gemspec
gemspec

platform :rbx do
  gem 'rubysl'
end

mri_2plus = [:mri_20, :mri_21, :mri_22, :mri_23]
ruby_2plus = [:ruby_20, :ruby_21, :ruby_22, :ruby_23]

group :tools do
  gem 'guard', platform: mri_2plus
  gem 'guard-bundler', platform: mri_2plus
  gem 'guard-rspec', platform: mri_2plus
  gem 'guard-cucumber', platform: mri_2plus
  gem 'guard-rubocop', platform: mri_2plus
  gem 'pry'
  gem 'pry-byebug', platform: mri_2plus
  gem 'pry-stack_explorer', platform: ruby_2plus
  group :darwin do
    gem 'ruby_gntp'
    gem 'rb-fsevent'
    gem 'relish', platform: mri_2plus
    gem 'lunchy'
  end
  gem 'yard'
  gem 'redcarpet'
  gem 'launchy'
end

gem 'thread_safe'

require File.expand_path('../test_lib/broker_config', __FILE__)

adapter = BrokerConfig.current_adapter.to_s
version = BrokerConfig.adapter_version
provider = BrokerConfig.provider

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

gem 'coveralls', require: false

platform :ruby_19 do
  gem 'json', '< 2'
  gem 'addressable', '< 2.5'
  gem 'tins', '~> 1.6.0'
end
