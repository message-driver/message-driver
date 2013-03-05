# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

default_rspec_opts = {cli: '-f doc', run_all: {cli: ''}}

group 'specs' do
  guard 'rspec', default_rspec_opts do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})          { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/(.+)\.rb$}) { "spec" }
    watch('spec/spec_helper.rb')       { "spec" }
  end
end

group 'features' do
  guard 'rspec', default_rspec_opts.merge(turnip: true) do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})          { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/(.+)\.rb$}) { "spec" }
    watch(%r{^spec/acceptance/(.+)\.feature$})
    watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})  { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
    watch('spec/spec_helper.rb')  { "spec" }
    watch('spec/turnip_helper.rb')  { "spec" }
  end
end
