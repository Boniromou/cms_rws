module Approval
  class Log < ActiveRecord::Base
    belongs_to :request
    attr_accessible :action, :action_by, :approval_request_id
    validates_presence_of :action, :action_by, :approval_request_id
    scope :by_action, -> action {where(:action => action)}

    def self.insert(action, action_by, request_id)
    	self.create!(:action => action, :action_by => action_by, :approval_request_id => request_id)
    end

    def format_json
      log = self.as_json
      log['created_at'] = log['created_at'].getlocal.strftime("%Y-%m-%d %H:%M:%S")
      log['updated_at'] = log['updated_at'].getlocal.strftime("%Y-%m-%d %H:%M:%S")
      log.recursive_symbolize_keys
    end
  end
end
