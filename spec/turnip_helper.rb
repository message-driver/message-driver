require 'message_driver'

adapter_file = File.expand_path("../../.adapter_under_test", __FILE__)
adapter = ENV['APDAPTER_UNDER_TEST'] || (File.exist?(adapter_file) && File.read(adapter_file).chomp)
broker_config = case adapter
         when 'bunny'
           {adapter: :bunny}
         when 'in_memory'
           {adapter: :in_memory}
         else
           {adapter: :in_memory}
         end

puts "Running Acceptance Test with adapter config: #{broker_config}"

MessageDriver.configure(broker_config)

Dir.glob("spec/acceptance/steps/**/*_steps.rb") { |f| load f, true }
