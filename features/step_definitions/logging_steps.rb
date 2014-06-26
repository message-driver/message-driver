require 'logger'

LOG_FILE_NAME = 'cucumber_log_file.log'

Given(/^I am logging to a log file(?: at the (#{STRING_OR_SYM}) level)?$/) do |level|
  step "an empty file named \"#{LOG_FILE_NAME}\""
  in_current_dir do
    @logger = Logger.new(LOG_FILE_NAME)
  end
  step "I set the log level to #{level || 'info'}"
  @orig_logger, MessageDriver.logger = MessageDriver.logger, @logger
end

Given(/^I set the log level to (#{STRING_OR_SYM})$/) do |level|
  level = level ? level.to_s.upcase : 'INFO'
  @logger.level = Logger::SEV_LABEL.find_index(level)
end

Then 'the log file should contain:' do |string|
  step "the file \"#{LOG_FILE_NAME}\" should contain:", string
end

After do
  if @logger
    @logger.close
    @logger = nil
  end
  if @orig_logger
    MessageDriver.logger = @orig_logger
    @orig_logger = nil
  end
end
