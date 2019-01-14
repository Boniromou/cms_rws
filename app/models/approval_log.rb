class ApprovalLog < ActiveRecord::Base
  attr_accessible :action_by, :id, :approval_request_id
end

