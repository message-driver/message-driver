Given "The following broker configuration:" do |src|
  test_runner.config_broker(src)
end

When "I execute the following code:" do |src|
  test_runner.run_test_code(src)
end

Then(/^I expect to find (#{NUMBER}) messages? on (#{STRING_OR_SYM})$/) do |count, destination|
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items
end

Then(/^I expect to find (#{NUMBER}) messages? on (#{STRING_OR_SYM}) with:$/) do |count, destination, table|
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items

  actual = messages.collect do |msg|
    table.headers.inject({}) do |memo, obj|
      memo[obj] = msg.send(obj)
      memo
    end
  end

  expect(actual).to eq(table.hashes)
end

Then(/^I expect it to raise "(.*?)"$/) do |error_msg|
  expect(test_runner.raised_error).to_not be_nil
  expect(test_runner.raised_error.to_s).to match error_msg
end

