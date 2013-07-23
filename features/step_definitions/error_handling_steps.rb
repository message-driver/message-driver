When "the broker goes down" do
  block_broker_port
end

When "the broker comes up" do
  unblock_broker_port
end

After do
  unblock_broker_port
end
