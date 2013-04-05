When "the broker goes down" do
  result = block_broker_port
end

When "the broker comes up" do
  result = unblock_broker_port
end

After do
  unblock_broker_port
end
