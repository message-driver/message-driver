# A sample Guardfile
# More info at https://github.com/guard/guard#readme

require File.join(File.dirname(__FILE__), 'test_lib', 'broker_config')

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

common_rspec_opts = {
  all_after_pass: true,
  cmd: 'bundle exec rspec -f doc',
  run_all: { cmd: 'bundle exec rspec' }
}
unit_spec_opts = common_rspec_opts.merge(
  spec_paths: ['spec/units']
)
integration_spec_opts = common_rspec_opts.merge(
  spec_paths: ["spec/integration/#{BrokerConfig.current_adapter}"],
  cmd_additional_args: '-t all_adapters'
)

group :tests_and_checks, halt_on_failure: true do
  group 'specs' do
    guard 'rspec', unit_spec_opts do
      watch(%r{^spec/units/.+_spec\.rb$})
      watch(%r{^lib/(.+)\.rb$})          { |m| "spec/units/#{m[1]}_spec.rb" }
      watch(%r{^spec/support/(.+)\.rb$}) { 'spec/units' }
      watch('spec/spec_helper.rb')       { 'spec/units' }
    end
  end

  group 'integration' do
    guard 'rspec', integration_spec_opts do
      watch(%r{^spec/integration/.+_spec\.rb$})
      watch(%r{^lib/(.+)\.rb$})          { |m| "spec/integration/#{m[1]}_spec.rb" }
      watch(%r{^spec/support/(.+)\.rb$}) { integration_spec_opts[:spec_paths] }
      watch('spec/spec_helper.rb')       { integration_spec_opts[:spec_paths] }
    end
  end

  group 'features' do
    guard('cucumber',
          all_on_start: false,
          cmd: "bundle exec cucumber --no-profile --color --strict --tag @all_adapters,@#{BrokerConfig.current_adapter} --tag ~@wip",
          cmd_additional_args: '--format pretty --tag ~@slow',
          run_all: {
            cmd_additional_args: '--format progress --tag ~@slow'
          }
         ) do
      watch(%r{^features/.+\.feature$})
      watch(%r{^features/support/.+$}) { 'features' }
      watch(%r{^features/step_definitions/(.+)_steps\.rb$}) { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'features' }
    end
  end

  guard :rubocop do
    watch(/.+\.rb$/)
    watch('Gemfile')
    watch('Guardfile')
    watch(/.+\.gemspec$/)
    watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
  end
end
