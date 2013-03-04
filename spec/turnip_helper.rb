require 'message_driver'

config = case ENV["ADAPTER_UNDER_TEST"]
         when 'bunny'
           {adapter: :bunny}
         when 'in_memory'
           {adapter: :in_memory}
         else
           {adapter: :in_memory}
         end

puts "Running Acceptance Test with adapter config: #{config}"

MessageDriver.configure(config)

Dir.glob("spec/acceptance/steps/**/*_steps.rb") { |f| load f, true }
