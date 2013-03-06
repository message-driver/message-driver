step "I have a destination :destination_name" do |destination_name|
  MessageDriver::Broker.define do |b|
    b.destination destination_name, destination_name, exclusive: true
  end
end
