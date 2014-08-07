if ENV['CI']
  require 'coveralls'
  Coveralls.wear_merged! do
    add_filter 'test_lib'
    add_filter 'spec'
    add_filter 'features'
    add_filter 'ci'
    add_filter 'examples'
    command_name(ENV['COMMAND_NAME']) if ENV['COMMAND_NAME']
  end
end
