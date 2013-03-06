step "I have a destination :destination_name" do |destination_name|
  MessageDriver::Broker.adapter.create_destination(destination_name)
end
