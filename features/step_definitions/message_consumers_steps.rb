Given "I have a message consumer" do |src|
  test_runner.run_config_code(src)
end

Given(/^I subscribe to (#{STRING_OR_SYM}) with (#{STRING_OR_SYM})$/) do |destination, consumer|
  MessageDriver::Broker.subscribe(destination, consumer)
end
