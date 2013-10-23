Given "I have a message consumer" do |src|
  test_runner.run_config_code(src)
  expect(test_runner).to have_no_errors
end

Given(/^I subscribe to (#{STRING_OR_SYM}) with (#{STRING_OR_SYM})$/) do |destination, consumer|
  MessageDriver::Client.subscribe(destination, consumer)
end

Given "I create a subscription" do |src|
  test_runner.run_test_code("@subscription = #{src}")
  expect(test_runner).to have_no_errors
end

When "I cancel the subscription" do
  test_runner.run_test_code("@subscription.unsubscribe")
  step "I allow for processing"
end

When "I let the subscription process" do
  step "I allow for processing"
  step "I cancel the subscription"
  expect(test_runner).to have_no_errors
end
