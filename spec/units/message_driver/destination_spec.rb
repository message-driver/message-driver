require 'spec_helper'

module MessageDriver::Destination
  describe Base do
    subject(:destination) { Base.new(nil, nil, nil, nil) }

    it "needs some real tests"

    include_examples "doesn't support #message_count"
  end
end
