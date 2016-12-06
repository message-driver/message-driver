RSpec::Matchers.define :have_no_errors do
  match do |test_runner|
    test_runner.raised_error.nil?
  end

  failure_message do |test_runner|
    err = test_runner.raised_error
    filtered = (err.backtrace || []).reject do |line|
      Cucumber::Core::Ast::StepInvocation::BACKTRACE_FILTER_PATTERNS.find { |p| line =~ p }
    end
    (["#{err.class}: #{err}"] + filtered).join("\n  ")
  end
end
