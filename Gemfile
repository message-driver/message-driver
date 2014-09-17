source 'https://rubygems.org'

# Specify your gem's dependencies in message-driver.gemspec
gemspec

platform :rbx do
  gem 'rubysl'
end

group :tools do
  gem 'guard', platform: [:mri_20, :mri_21]
  gem 'guard-bundler', platform: [:mri_20, :mri_21]
  gem 'guard-rspec', platform: [:mri_20, :mri_21]
  gem 'guard-cucumber', platform: [:mri_20, :mri_21]
  gem 'guard-rubocop', platform: [:mri_20, :mri_21]
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
end

require File.expand_path('../test_lib/broker_config', __FILE__)

adapter = BrokerConfig.current_adapter.to_s
version = BrokerConfig.adapter_version
provider = BrokerConfig.provider

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

case provider
when :rabbitmq
  gem 'rabbitmq_http_api_client', '> 1.3.0', github: 'soupmatt/rabbitmq_http_api_client', branch: :master
end

gem 'coveralls', require: false
