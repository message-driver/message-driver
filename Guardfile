# A sample Guardfile
# More info at https://github.com/guard/guard#readme

require File.join(File.dirname(__FILE__), 'test_lib', 'broker_config')

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

unit_spec_opts = {spec_paths: ["spec/units"], cli: '-f doc', run_all: {cli: ''}}
acceptance_spec_opts = {spec_paths: ["spec/integration"], cli: '-f doc -t all_adapters', run_all: {cli: '-t all_adapters'}}

group 'specs' do
  guard 'rspec', unit_spec_opts do
    watch(%r{^spec/units/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})          { |m| "spec/units/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/(.+)\.rb$}) { "spec" }
    watch('spec/spec_helper.rb')       { "spec" }
  end
end

group 'integration' do
  guard 'rspec', acceptance_spec_opts do
    watch(%r{^spec/integration/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})          { |m| "spec/integration/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/(.+)\.rb$}) { "spec" }
    watch('spec/spec_helper.rb')       { "spec" }
  end

  cucumber_cli = "--no-profile --color --format progress --strict --tag @all_adapters,@#{BrokerConfig.current_adapter}"
  guard 'cucumber', change_format: 'pretty', cli: cucumber_cli do
    watch(%r{^features/.+\.feature$})
    watch(%r{^features/support/.+$})          { 'features' }
    watch(%r{^features/step_definitions/(.+)_steps\.rb$}) { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'features' }
  end
end


