require 'message_driver'

Dir.glob("spec/acceptance/steps/**/*_steps.rb") { |f| load f, true }
