source 'https://rubygems.org'

# Specify your gem's dependencies in message-driver.gemspec
gemspec

group :development do
  gem 'bunny', '~> 0.9.2', git: "git://github.com/soupmatt/bunny.git", branch: :'fix-issue-153'
  gem 'stomp', '~> 1.2.10'
end

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
