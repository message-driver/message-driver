RSpec::Matchers.define :match_message_table do |expected_tbl|
  define_method :expected_hash do
    @expected_hash ||= expected_tbl.hashes
  end

  define_method :messages_to_hash do |messages|
    messages.map do |msg|
      expected_tbl.headers.each_with_object({}) do |method, hash|
        hash[method] = msg.send(method)
      end
    end
  end

  match do |messages|
    @actual = messages_to_hash(messages)
    expect(@actual).to match_array(expected_hash)
    true
  end

  failure_message do |_|
    "expected #{expected_hash} and got #{@actual}"
  end

  description do
    "contain messages #{expected_hash}"
  end
end
