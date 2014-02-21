# A sample Guardfile
# More info at https://github.com/guard/guard#readme

require File.join(File.dirname(__FILE__), 'test_lib', 'broker_config')

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

common_rspec_opts = { all_after_pass: true }
unit_spec_opts = common_rspec_opts.merge({ spec_paths: ["spec/units"], cmd: 'rspec -f doc', run_all: { cmd: 'bundle exec rspec' } })
integration_spec_opts = common_rspec_opts.merge({ spec_paths: ["spec/integration/#{BrokerConfig.current_adapter}"], cmd: 'bundle exec rspec -f doc -t all_adapters', run_all: { cmd: 'bundle exec rspec -t all_adapters' } })

group 'specs' do
  guard 'rspec', unit_spec_opts do
    watch(%r{^spec/units/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})          { |m| "spec/units/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/(.+)\.rb$}) { "spec" }
    watch('spec/spec_helper.rb')       { "spec" }
  end
end

group 'integration' do
  guard 'rspec', integration_spec_opts do
    watch(%r{^spec/integration/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})          { |m| "spec/integration/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/(.+)\.rb$}) { "spec" }
    watch('spec/spec_helper.rb')       { "spec" }
  end
end

group 'features' do
  cucumber_cli = "--no-profile --color --format progress --strict --tag @all_adapters,@#{BrokerConfig.current_adapter} --tag ~@wip"
  cucumber_run_all_cli = "#{cucumber_cli} --tag ~@slow"
  guard 'cucumber', change_format: 'pretty', all_on_start: false, cli: cucumber_cli, run_all: { cli: cucumber_run_all_cli } do
    watch(%r{^features/.+\.feature$})
    watch(%r{^features/support/.+$})          { 'features' }
    watch(%r{^features/step_definitions/(.+)_steps\.rb$}) { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'features' }
  end
end


