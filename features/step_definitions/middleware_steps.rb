Given('I have a middleware class') do |src|
  write_file('feature_middleware.rb', src)
  in_current_dir { load './feature_middleware.rb' }
end

When(/^I append middleware "(.*?)" to (#{STRING_OR_SYM})$/) do |class_name, dest_name|
  klass = Object.const_get(class_name)
  destination = test_runner.fetch_destination(dest_name)
  destination.middleware.append klass
end
