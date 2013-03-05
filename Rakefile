require 'bundler/gem_tasks'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:turnip) do |t|
  t.rspec_path = "rspec -r turnip/rspec"
end

task :default => [:spec, :turnip]
