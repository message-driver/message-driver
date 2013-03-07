steps_for :publishing_a_message do
  include MessageDriver::MessagePublisher

  step "I publish a message to :dest_name" do |dest_name|
    publish(dest_name, "Test Message")
  end

  step "it ends up at the destination :dest_name" do |dest_name|
    result = pop_message(dest_name)
    expect(result).to be_a MessageDriver::Message::Base
    expect(result.body).to eq("Test Message")
  end
end
