RSpec::Matchers.define :match_message_table do |expected|
  match do |messages|
    actual = messages.collect do |msg|
      expected.headers.inject({}) do |memo, obj|
        memo[obj] = msg.send(obj)
        memo
      end
    end
    actual == expected.hashes
  end
end
