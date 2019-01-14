module Approval
  module Models
  	def self.submit(target, target_id, action, data, current_user)
      execute do
    		Request.submit(target, target_id, action, data, current_user)
    		{error_code: 'OK', error_msg: 'Approval submit successfully.'}
      end
  	end

  	def self.update_status(target, target_id, action, operation, current_user)
      execute do
    		Request.update_status(target, target_id, action, operation, current_user)
    		{error_code: 'OK', error_msg: 'Approval update status successfully.'}
      end
  	end

  	def self.get_details(target, target_id, action)
      execute do
        response = Request.get_details(target, target_id, action)
        response.merge!({error_code: 'OK', error_msg: 'Approval get details successfully.'})
      end
  	end

    def self.get_details_by_target_ids(target, target_id, action)
      execute do
        {
          response: Request.get_details_by_target_ids(target, target_id, action),
          error_code: 'OK',
          error_msg: 'Approval get details by target successfully.'
        }
      end
    end

  	def self.get_status_by_target_ids(target, target_id, action)
      execute do
        {
          response: Request.get_status_by_target_ids(target, target_id, action),
          error_code: 'OK',
          error_msg: 'Approval get status by target successfully.'
        }
      end
  	end

    private
    def self.execute(&block)
      yield
    rescue ApprovalError => e
      Rails.logger.error(e.message)
      Rails.logger.error e.backtrace.join("\n")
      {error_code: e.class.name.demodulize, error_msg: e.error_message}
    rescue StandardError => e
      Rails.logger.error(e.message)
      Rails.logger.error e.backtrace.join("\n")
      {error_code: 'StandardError', error_msg: e.message}
    end
  end
end
