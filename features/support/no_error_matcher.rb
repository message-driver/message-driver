RSpec::Matchers.define :have_no_errors do
  match do |test_runner|
    test_runner.raised_error == nil
  end

  failure_message_for_should do |test_runner|
    err = test_runner.raised_error
    filtered = (err.backtrace || []).reject do |line|
      Cucumber::Ast::StepInvocation::BACKTRACE_FILTER_PATTERNS.detect { |p| line =~ p }
    end
    (["#{err.class}: #{err}"]+filtered).join("\n  ")
  end
end
