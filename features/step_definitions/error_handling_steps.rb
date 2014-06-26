When 'the broker goes down' do
  block_broker_port
  sleep 2
end

When 'the broker comes up' do
  unblock_broker_port
  sleep 20
end

After do
  unblock_broker_port
end
