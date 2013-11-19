require 'bunny'

module Bunny
  class Session
    def cleanup_threads
      log_errors { self.maybe_shutdown_heartbeat_sender }
      log_errors { self.maybe_shutdown_reader_loop }
      log_errors { self.close_transport }
    end

    def log_errors
      begin
        yield
      rescue => e
        @logger.info "#{e.class}: #{e.to_s}"
      end
    end
  end
end
