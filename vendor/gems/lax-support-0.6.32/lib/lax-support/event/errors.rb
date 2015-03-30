module LaxSupport
  module Event
    class EventError < StandardError
    end
   
    class ProtectedEventParameter < EventError
      def initialize(name)
        super("Can NOT modify protected event parameter: '#{name.inspect}'")
      end
    end

    class InvalidEventMessage < EventError
      def initialize
        super("Either hash-based or yaml-based message is expected.")
      end
    end

    class SignatureMismatched < EventError
      def initialize
        super("Message signature is mismatched.")
      end
    end

    class MissingEventParameter < EventError
      def initialize(name)
        super("Required event paremeter is missing: '#{name.inspect}'")
      end
    end
  end
end
