module Approval
  class Request < ActiveRecord::Base
  	PENDING  = 'pending'
  	APPROVED = 'approved'
  	CANCELED = 'canceled'
  	CLOSED   = 'closed'

  	SUBMIT  = 'submit'
  	APPROVE = 'approve'
    CANCEL  = 'cancel'
  	PUBLISH = 'publish'

  	OPERATIONS = {
  		APPROVE => APPROVED,
      CANCEL => CANCELED,
  		PUBLISH => CLOSED
  	}

    NEXT_STEPS = {
      PENDING => [APPROVE, CANCEL],
      APPROVED => [PUBLISH, CANCEL],
      CANCELED => [SUBMIT],
      CLOSED => [SUBMIT]
    }

    attr_accessible :target, :target_id, :action, :data, :status
    serialize :data, JSON
    validates_presence_of :target, :target_id, :action
	  has_many :logs, foreign_key: "approval_request_id"

    scope :by_target, -> target {where(:target => target)}
    scope :by_action, -> action {where(:action => action)}
    scope :by_target_id, -> target_id {where(:target_id => target_id)}
    scope :by_status, -> status {where(:status => status)}
    scope :ongoing_requests, -> {where(:status => [PENDING, APPROVED])}
    scope :get_request, -> target, target_id, action {where(:target => target, :target_id => target_id, :action => action)}

    ['approve', 'cancel'].each do |method_name|
      define_method method_name do |current_user|
        raise ApprovalUpdateStatusFailed.new("#{method_name} failed: current status[#{status}] can not do this operation.") unless valid_update_status(method_name)
        self.status = OPERATIONS[method_name]
        transaction do
          self.save!
          Log.insert(method_name, current_user, id)
        end
      end
    end

    def self.get_requests_list(target, search_by, action, status, all)
      request_lists = []
      requests = self.includes(:logs).by_target(target).by_action(action).by_status(status)
      requests = filter_requests(requests, target, search_by)
      requests.each do |request|
        request_list = request.format_json
        request.logs.each do |log|
          request_list["#{log.action}_by".to_sym] = log.action_by
          request_list["#{log.action}_at".to_sym] = log.updated_at.getlocal.strftime("%Y-%m-%d %H:%M:%S")
        end
        request_lists << request_list
      end
      request_lists
    end

    def self.get_logs_list(target, search_by, action, all)
      log_lists = []
      requests = self.includes(:logs).by_target(target).by_action(action).where(approval_logs: {action: ['cancel']})
      requests = filter_requests(requests, target, search_by)
      requests.each do |request|
        request_list = request.format_json
        request.logs.each do |log|
          log_list = log.format_json
          log_list[:request] = request_list
          log_lists << log_list
        end
      end
      log_lists
    end

    def self.submit(target, target_id, action, data, current_user)
    	if self.ongoing_requests.get_request(target, target_id, action).present?
    		raise ApprovalSubmitFailed.new('Approval Request submit failed: Exist ongoing approval request.')
    	end
    	transaction do
	    	request = self.create!(:target => target, :target_id => target_id, :action => action, :data => data)
	    	Log.insert(SUBMIT, current_user, request.id)
	    end
    end

    def self.update_status(target, target_id, action, operation, current_user)
    	unless OPERATIONS.keys.include?(operation)
    		raise ApprovalUndefinedOperation.new('Approval update status failed: undefined this operation')
    	end
    	request = self.ongoing_requests.get_request(target, target_id, action).last
    	if request.blank?
    		raise ApprovalNotExistRequest.new('Approval update status failed: not exist ongoing approval request.')
    	end
    	unless request.valid_update_status(operation)
    		raise ApprovalUpdateStatusFailed.new("Approval update status failed: current status[#{request.status}] can not do this operation.")
    	end
	    request.status = OPERATIONS[operation]
    	transaction do
	    	request.save!
	    	Log.insert(operation, current_user, request.id)
	    end
    end

    def self.get_details(target, target_id, action)
      result = {}
      request = self.get_request(target, target_id, action).last
      return result if request.blank?
      result = request.as_json
      result[:request_logs] = request.logs.select(%w(action action_by created_at)).as_json
      result[:next_steps] = NEXT_STEPS[request['status']]
      result.recursive_symbolize_keys
    end

    def self.get_details_by_target_ids(target, target_ids, action)
      requests = self.ongoing_requests.by_target(target).by_action(action).by_target_id(target_ids)
      requests = requests.map do |request|
        data = (request.data.is_a? String) ? JSON.parse(request.data) : request.data
        [request.target_id, request.as_json.merge(data).slice!('data')]
      end
      Hash[requests].recursive_symbolize_keys
    end

    def self.get_status_by_target_ids(target, target_ids, action)
      requests = self.ongoing_requests.get_request(target, target_ids, action).select(%w(target_id status))
      Hash[requests.map {|req| [req.target_id, req.status]}].recursive_symbolize_keys
    end

    def self.filter_requests(requests, target, search_by)
      target_ids = target.classify.constantize.where(search_by).map(&:id) if search_by.present?
      target_ids ||= []
      requests.delete_if {|request| !target_ids.include?(request.target_id)}
      requests
    end

    def valid_update_status(operation)
    	flag = false
    	case operation
    	when APPROVE
    		flag = true if status == PENDING
    	when PUBLISH
    		flag = true if status == APPROVED
      when CANCEL
        flag = true if status == PENDING || status == APPROVED
    	end
    	flag
    end

    def format_json
      data = (self.data.is_a? String) ? JSON.parse(self.data) : self.data
      request = self.as_json.merge(data).slice!('data')
      request['created_at'] = request['created_at'].getlocal.strftime("%Y-%m-%d %H:%M:%S")
      request['updated_at'] = request['updated_at'].getlocal.strftime("%Y-%m-%d %H:%M:%S")
      request.recursive_symbolize_keys
    end
  end
end
