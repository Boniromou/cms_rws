module Approval
	class ApprovalError < StandardError
		attr_reader :error_code, :error_level, :error_message, :data

    def initialize(msg='system error', data={})
      @error_code = 500
      @error_level = 'warning'
      @error_message = msg
      @data = data
    end
	end

	class ApprovalSubmitFailed < ApprovalError; end
  class ApprovalUpdateStatusFailed < ApprovalError; end
  class ApprovalUndefinedOperation < ApprovalError; end
  class ApprovalNotExistRequest < ApprovalError; end
end