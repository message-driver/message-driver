require 'rubygems'
require 'bundler/setup'

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
require 'cucumber/rake/task'

require 'coveralls/rake/task'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new do |t|
    t.fail_on_error = false
  end
rescue LoadError
  puts 'rubocop not present'
  task 'rubocop'
end

namespace :spec do
  desc 'Run unit specs'
  RSpec::Core::RakeTask.new(:units) do |t|
    t.pattern = './spec/units{,/*/**}/*_spec.rb'
  end

  desc 'Run the integration specs'
  RSpec::Core::RakeTask.new(:integrations) do |t|
    t.rspec_opts = '--tag all_adapters'
    t.pattern = "./spec/integration/#{BrokerConfig.current_adapter}{,/*/**}/*_spec.rb"
  end

  cucumber_opts = "--format progress --tag @all_adapters,@#{BrokerConfig.current_adapter} --tag ~@wip"
  cucumber_opts += ' --tag ~@no_ci' if ENV['CI'] == 'true' && ENV['ADAPTER'] && ENV['ADAPTER'].start_with?('bunny')
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = cucumber_opts
  end

  task all: [:units, :integrations, :features]
end

desc 'run all the specs'
task spec: ['rabbitmq:reset_vhost', 'spec:all']

begin
  require 'yard'
  require 'launchy'

  YARD::Rake::YardocTask.new(:docs)
  namespace :docs do

    desc 'open the documentation for this gem in your browser'
    task open: [:docs] do
      Launchy.open("file:///#{File.join(Dir.pwd, 'doc', 'index.html')}")
    end
  end
rescue LoadError
  puts "couldn't load yard gems, doc tasks not available"
  task :docs
end

namespace :rabbitmq do
  desc 'Reset rabbit vhost'
  task :reset_vhost do
    rabbitmqctl = ENV['CI'] ? 'sudo rabbitmqctl' : 'rabbitmqctl'
    vhost = ENV['VHOST'] || 'message-driver-test'
    system "#{rabbitmqctl} delete_vhost #{vhost}"
    system "#{rabbitmqctl} add_vhost #{vhost}"
    system "#{rabbitmqctl} set_permissions -p #{vhost} guest \".*\" \".*\" \".*\""
  end
end

def set_adapter_under_test(adapter)
  system "echo #{adapter} > #{File.join(File.dirname(__FILE__), '.adapter_under_test')}"
end

Coveralls::RakeTask.new
desc 'run with code coverage'
task ci: ['spec', 'rubocop', 'coveralls:push']

namespace :undertest do
  BrokerConfig.all_adapters.each do |adapter|
    desc "set the adapter under test to #{adapter}"
    task adapter do
      set_adapter_under_test(adapter)
    end
  end
end

task default: [:spec, :rubocop]
