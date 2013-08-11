require 'rubygems'
require 'bundler/setup'

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
require 'cucumber/rake/task'

#require File.join(File.dirname(__FILE__), 'test_lib', 'broker_config')

namespace :spec do
  desc "Run unit specs"
  RSpec::Core::RakeTask.new(:units) do |t|
    t.pattern = "./spec/units{,/*/**}/*_spec.rb"
  end

  desc "Run the integration specs"
  RSpec::Core::RakeTask.new(:integrations) do |t|
    t.rspec_opts = "--tag all_adapters"
    t.pattern = "./spec/integration/#{BrokerConfig.current_adapter}{,/*/**}/*_spec.rb"
  end

  cucumber_opts = "--format progress --tag @all_adapters,@#{BrokerConfig.current_adapter} --tag ~@wip"
  cucumber_opts += " --tag ~@no_ci" if ENV['CI']=='true' && ENV['ADAPTER']=='bunny'
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = cucumber_opts
  end

  desc "run all the specs"
  task :all => [:units, :integrations, :features]

  desc "run all the specs for each adapter"
  task :all_adapters do
    current_adapter = BrokerConfig.current_adapter
    BrokerConfig.all_adapters.each do |adapter|
      set_adapter_under_test(adapter)
      system("rake spec:all")
    end
    set_adapter_under_test(current_adapter)
  end
end

def set_adapter_under_test(adapter)
  system "echo #{adapter} > #{File.join(File.dirname(__FILE__), '.adapter_under_test')}"
end

namespace :undertest do
  BrokerConfig.all_adapters.each do |adapter|
    desc "set the adapter under test to #{adapter}"
    task adapter do
      set_adapter_under_test(adapter)
    end
  end
end

task :default => ["spec:all"]
