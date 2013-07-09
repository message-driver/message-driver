Given "I am connected to the broker" do
  MessageDriver.configure(BrokerConfig.config)
end

Given "the following broker configuration" do |src|
  step "I am connected to the broker"
  test_runner.run_config_code(src)
end

Given(/^I have a destination (#{STRING_OR_SYM})$/) do |destination|
  MessageDriver::Broker.define do |b|
    b.destination(destination, destination.to_s)
  end
end

When(/^I send the following messages to (#{STRING_OR_SYM})$/) do |destination, table|
  table.hashes.each do |msg|
    MessageDriver::Client.publish(destination, msg[:body])
  end
end

When "I execute the following code" do |src|
  test_runner.run_test_code(src)
end

Then(/^I expect to find (#{NUMBER}) messages? on (#{STRING_OR_SYM})$/) do |count, destination|
  expect(test_runner).to have_no_errors
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items
end

Then(/^I expect to find the following (#{NUMBER}) messages? on (#{STRING_OR_SYM})$/) do |count, destination, table|
  expect(test_runner).to have_no_errors
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items
  expect(messages).to match_message_table(table)
end

Then(/^I expect to find the following message on (#{STRING_OR_SYM})$/) do |destination, table|
  dest = destination.kind_of?(Symbol) ? destination.inspect : destination.to_s
  step "I expect to find the following 1 message on #{dest}", table
end

Then(/^I expect it to raise "(.*?)"$/) do |error_msg|
  expect(test_runner.raised_error).to_not be_nil
  expect(test_runner.raised_error.to_s).to match error_msg
  test_runner.raised_error = nil
end

Then(/^I expect it to raise a (.*?) error$/) do |error_type|
  expect(test_runner.raised_error).to_not be_nil
  expect(test_runner.raised_error.class.to_s).to match error_type
  test_runner.raised_error = nil
end

Then "I expect to have no errors" do
  expect(test_runner).to have_no_errors
end

Before do |current_scenario|
  test_runner.current_feature_file = current_scenario.feature.file
end
