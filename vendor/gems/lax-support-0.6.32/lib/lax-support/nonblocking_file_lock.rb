if RUBY_VERSION =~ /1.8/
  require 'ftools'
else
  require 'fileutils'
end

module LaxSupport
  #
  # +NonblockingFileLock+ is a mix-in module used to implement pid lock file.
  # This is mainly used to guarantee one and only one process to run at a time. 
  #
  # Here is one example:
  #
  #     class YourObject
  #       # Mix-in the module first
  #       include LaxSupport::NonblockingFileLock
  #       # Specify the full path for the lock file
  #       set_lock_file File.join(Rails.root, 'tmp', 'pids', 'your_object.pid')
  #     
  #       def initialize
  #         # At the beginning of any business logic is performed, 
  #         # you should try to obtain the file lock first.
  #         # If fail to obtain the file lock, LaxSupport::NonblockingFileLock::FailedToLockFile
  #         # will be raised.
  #         open_file_lock
  #         puts "File lock (#{self.class.lock_file}) is obtained successfully"
  #
  #         # Other initialization here 
  #       end
  #     
  #       def run # Your main method to execute business logic
  #         # Business logic here
  #         
  #         # At the end, release the file lock
  #         close_file_lock
  #       end
  #     end
  module NonblockingFileLock

    class FailedToLockFile < StandardError
      def initialize(lock_file)
        super("Failed to obtain file lock: #{lock_file}")
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      def set_lock_file(lock_file)
        @_lock_file = lock_file
      end

      def lock_file
        @_lock_file || self.superclass.instance_variable_get('@_lock_file') 
      end
    end

    module InstanceMethods
      def open_file_lock
        return if @_lock_fh 
        @_lock_fh = open(self.class.lock_file, 'w')
        if @_lock_fh.flock(File::LOCK_EX | File::LOCK_NB)
          @_lock_fh.puts $$
          #puts "File lock (#{self.class.lock_file}) is obtained successfully" 
        else
          @_lock_fh.close
          @_lock_fh = nil
          raise FailedToLockFile.new(self.class.lock_file)
        end
      end
  
      def close_file_lock
        @_lock_fh.flock(File::LOCK_UN)
        @_lock_fh.close
        @_lock_fh = nil
        File.unlink(self.class.lock_file)
      end
    end

  end
end
