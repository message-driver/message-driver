class TestRunner
  include MessageDriver::MessagePublisher

  attr_accessor :raised_error

  def config_broker(src, file)
    instance_eval(src, file)
  end

  def run_test_code(src, file)
    begin
      instance_eval(src, file)
    rescue => e
      @raised_error = e
    end
  end

  def fetch_messages(destination)
    result = []
    begin
      msg = pop_message(destination)
      result << msg unless msg.nil?
    end until msg.nil?
    result
  end
end

def test_runner
  @test_runner ||= TestRunner.new
end

step "The following broker configuration:" do |src|
  test_runner.config_broker(src, example.file_path)
end

step "I execute the following code:" do |src|
  test_runner.run_test_code(src, example.file_path)
end

step "I expect to find :count message(s) on :sym_or_string" do |count, destination|
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items
end

step "I expect to find :count message(s) on :sym_or_string with:" do |count, destination, table|
  messages = test_runner.fetch_messages(destination)
  expect(messages).to have(count).items

  actual = messages.collect do |msg|
    table.headers.inject({}) do |memo, obj|
      memo[obj] = msg.send(obj)
      memo
    end
  end

  expect(actual).to eq(table.hashes)
end

step "I expect it to raise :error_msg" do |error_msg|
  expect(test_runner.raised_error).to_not be_nil
  expect(test_runner.raised_error.to_s).to match error_msg
end

placeholder :count do
  match(/\d+/) do |count|
    count.to_i
  end

  match(/no/) do
    0
  end
end

placeholder :sym_or_string do
  match(/:\w+/) do |sym|
    sym.slice(1, sym.length-1).to_sym
  end
  match(/\w+/) do |str|
    str
  end
end
