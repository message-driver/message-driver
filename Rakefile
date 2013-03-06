require 'bundler/gem_tasks'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--tag ~type:integration"
end

RSpec::Core::RakeTask.new(:features) do |t|
  t.rspec_opts = "--tag type:integration"
  t.pattern = "./spec{,/*/**}/*{_spec.rb,.feature}"
end

task :default => [:spec, :features]
