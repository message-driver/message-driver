Then 'I expect all the publishes to have been acknowledged' do
  ctx = test_runner.fetch_current_adapter_context
  expect(ctx.channel).to be_using_publisher_confirms
  expect(ctx.channel.unconfirmed_set).to be_empty
end

Then 'I expect that we are not in transaction mode' do
  ctx = test_runner.fetch_current_adapter_context
  expect(ctx).not_to be_transactional
end
