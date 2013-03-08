# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

unit_spec_opts = {spec_paths: ["spec/units"], cli: '-f doc', run_all: {cli: ''}}
acceptance_spec_opts = {spec_paths: ["spec/integration", "spec/acceptance"], cli: '-f doc -t all_adapters', run_all: {cli: '-t all_adapters'}}

group 'specs' do
  guard 'rspec', unit_spec_opts do
    watch(%r{^spec/units/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})          { |m| "spec/units/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/(.+)\.rb$}) { "spec" }
    watch('spec/spec_helper.rb')       { "spec" }
  end
end

group 'features' do
  guard 'rspec', acceptance_spec_opts do
    watch(%r{^spec/integration/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})          { |m| "spec/integration/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/(.+)\.rb$}) { "spec" }
    watch(%r{^spec/acceptance/(.+)\.feature$})
    watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})  { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
    watch('spec/spec_helper.rb')  { "spec" }
  end
end
