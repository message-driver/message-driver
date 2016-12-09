module MessageDriver
  class TestAdapter < Adapters::Base
    def initialize(broker, _config)
      @broker = broker
    end

    def build_context
      TestContext.new(self)
    end
  end

  class TestContext < Adapters::ContextBase
    def handle_create_destination(_name, _dest_options = nil, _message_props = nil); end

    def handle_publish(_destination, _body, _dest_options = nil, _message_props = nil); end

    def handle_pop_message(_destination, _options = nil); end
  end
end
