require 'benchmark'

module LaxSupport
  module SimpleStore
    DEFAULT_LOCK_RETRY = 5   # times
    DEFAULT_EXPIRY = 30 # seconds

    class LockError < StandardError; end
  
    module LockMixin
      def synchronize(key, lock_expiry = DEFAULT_EXPIRY, retries = DEFAULT_LOCK_RETRY)
        if recursive_lock?(key)
          yield
        else
          acquire_lock(key, lock_expiry, retries)
          begin 
            yield
          ensure
            release_lock(key)
          end
        end
      end

      def acquire_lock(key, lock_expiry = DEFAULT_EXPIRY, retries = DEFAULT_LOCK_RETRY)
        retries.times do |count|
          response = @lock.add("lock/#{key}", Process.pid, {:expires_in=>lock_expiry})
          return if response == "STORED\r\n"
          exponential_sleep(count) unless count == retries - 1
        end
        raise LockError, "Could NOT acquire store lock for: #{key}"
      end

      def release_lock(key)
        @lock.delete("lock/#{key}")
      end

      private

      def exponential_sleep(count)
        sleep((2**count) / 2.0) 
      end
        
      def recursive_lock?(key)
        @lock["lock/#{key}"] == Process.pid
      end
 
    end

    class Lock
      include LockMixin
   
      def initialize(store)
        @lock = store
      end
    end
  end
end
