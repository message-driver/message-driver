Given "The following broker configuration:" do |src|
  test_runner.config_broker(src)
end

When "I execute the following code:" do |src|
  test_runner.run_test_code(src)
end

Then(/^I expect to find (#{NUMBER}) messages? on (#{STRING_OR_SYM})$/) do |count, destination|
  expect(test_runner).to have_no_errors
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items
end

Then(/^I expect to find (#{NUMBER}) messages? on (#{STRING_OR_SYM}) with:$/) do |count, destination, table|
  expect(test_runner).to have_no_errors
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items
  expect(messages).to match_message_table(table)
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
