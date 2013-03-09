require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
require 'cucumber/rake/task'

require File.join(File.dirname(__FILE__), 'test_lib', 'broker_config')

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/units{,/*/**}/*_spec.rb"
end

RSpec::Core::RakeTask.new(:integrations) do |t|
  t.rspec_opts = "--tag all_adapters"
  t.pattern = "./spec/integration{,/*/**}/*_spec.rb"
end

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format progress --tag @all_adapters,@#{BrokerConfig.current_adapter}"
end

task :default => [:spec, :integrations, :cucumber]
