module LaxSupport
  module ServiceController
  
    class InvalidOptions < StandardError
      def initialize(errors)
        error_msg = ''
        errors.each_pair do |key, value|
          error_msg += "    #{key.inspect} #{value}\n"
        end
        super("Following invalid options are found:\n#{error_msg}")
      end
    end

    class UnknownOperation < StandardError
      def initialize(operation)
        super("Unknown operation is requested: #{@operation}")
      end
    end

  end
end
