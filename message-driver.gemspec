# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'message_driver/version'

Gem::Specification.new do |gem|
  gem.name          = "message-driver"
  gem.version       = Message::Driver::VERSION
  gem.authors       = ["Matt Campbell"]
  gem.email         = ["matt@soupmatt.com"]
  gem.description   = %q{Easy message queues for ruby using AMQ, STOMP and others}
  gem.summary       = %q{Easy message queues for ruby}
  gem.homepage      = "https://github.com/soupmatt/message_driver"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 1.9.2'

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "turnip"
  gem.add_development_dependency "bunny", "0.9.0pre7"
end
