module MessageDriver
  class Exception < ::Exception; end

  class WrappedException < Exception
    attr_reader :other

    def initialize(other, msg=nil)
      super(msg || other.to_s)
      @other = other
    end
  end

  class QueueNotFound < WrappedException; end

  class ConnectionException < WrappedException; end

  class TransactionRollbackOnly < Exception; end
end
