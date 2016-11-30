# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'message_driver/version'

Gem::Specification.new do |gem|
  gem.name          = 'message-driver'
  gem.version       = MessageDriver::VERSION
  gem.authors       = ['Matt Campbell']
  gem.email         = ['message-driver@soupmatt.com']
  gem.description   = 'Easy message queues for ruby using AMQ, STOMP and others'
  gem.summary       = 'Easy message queues for ruby'
  gem.homepage      = 'https://github.com/message-driver/message-driver'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($RS)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^(test|spec|features)\//)
  gem.require_paths = %w(lib)

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3.5.0'
  gem.add_development_dependency 'cucumber', '~> 1.3.20'
  gem.add_development_dependency 'aruba', '~> 0.14.1'
end
