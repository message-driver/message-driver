Given "I am connected to the broker" do
  MessageDriver.configure(broker_config)
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

Given(/^I have a destination (#{STRING_OR_SYM}) with no messages on it$/) do |destination|
  dest = destination.kind_of?(Symbol) ? destination.inspect : destination.to_s
  step "I have a destination #{dest}"
  test_runner.purge_destination(destination)
end

Given(/^I have the following messages? on (#{STRING_OR_SYM})$/) do |destination, table|
  test_runner.purge_destination(destination)
  dest = destination.kind_of?(Symbol) ? destination.inspect : destination.to_s
  step "I send the following messages to #{dest}", table
end

Given(/^I have no messages on (#{STRING_OR_SYM})$/) do |destination|
  test_runner.purge_destination(destination)
end

When(/^I send the following messages? to (#{STRING_OR_SYM})$/) do |destination, table|
  table.hashes.each do |msg|
    MessageDriver::Client.publish(destination, msg[:body])
  end
end

When "I execute the following code" do |src|
  test_runner.run_test_code(src)
end

When "I reset the context" do
  MessageDriver::Client.current_adapter_context.invalidate
end

When "I allow for processing" do
  test_runner.pause_if_needed
end

Then(/^I expect to find (#{NUMBER}) messages? on (#{STRING_OR_SYM})$/) do |count, destination|
  expect(test_runner).to have_no_errors
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items, "expected #{count} messages, but got these instead: #{messages.map(&:body)}"
end

Then(/^I expect to find the following (#{NUMBER}) messages? on (#{STRING_OR_SYM})$/) do |count, destination, table|
  expect(test_runner).to have_no_errors
  messages = test_runner.fetch_messages(destination)
  expect(messages).to match_message_table(table)
  expect(messages).to have(count).items
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
  err = test_runner.raised_error
  expect(err).to_not be_nil
  expect(err.class.to_s).to match error_type
  test_runner.raised_error = nil
end

Then "I expect to have no errors" do
  expect(test_runner).to have_no_errors
end

Before do |current_scenario|
  test_runner.current_feature_file = current_scenario.feature.file
end
