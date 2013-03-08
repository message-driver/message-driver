require 'bundler/gem_tasks'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/units{,/*/**}/*_spec.rb"
end

RSpec::Core::RakeTask.new(:features) do |t|
  t.rspec_opts = "--tag all_adapters"
  t.pattern = "./spec/{acceptance,integration}{,/*/**}/*{_spec.rb,.feature}"
end

task :default => [:spec, :features]
