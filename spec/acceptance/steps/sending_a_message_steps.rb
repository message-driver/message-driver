steps_for :sending_a_message do
  include MessageDriver::MessageSender
  include MessageDriver::MessageReceiver

  step "I send a message to :dest_name" do |dest_name|
    send_message(dest_name, "Test Message")
  end

  step "it ends up at the destination :dest_name" do |dest_name|
    result = pop_message(dest_name)
    expect(result).to_not be_nil
  end
end
