require "rails_helper"

describe "ApprovalLogSpec" do
	before :each do
    @req = create(:request)
    @log = create(:log, :approval_request_id => @req.id)
    @current_user = "portal.admin@mo.laxino.com"
  end

	describe "insert" do
		def valid_insert_error(log)
			flag = false
			log_count = Approval::Log.count
			begin
				log = Approval::Log.insert(log.action, log.action_by, log.approval_request_id)
			rescue ActiveRecord::RecordInvalid
				flag = true
			end
			expect(flag).to eq true
			expect(Approval::Log.count).to eq log_count
		end

		it "approval log insert successfully" do
			log_count = Approval::Log.count
			action = Approval::Request::SUBMIT
			action_by = @current_user
			request_id = @req.id
			log = Approval::Log.insert(action, action_by, request_id)
			expect(log).not_to be_nil
			expect(log.action).to eq action
			expect(log.action_by).to eq action_by
			expect(log.approval_request_id).to eq request_id
			expect(Approval::Log.count).to eq log_count + 1
		end

		it "approval log insert failed: action is nil" do
			@log.action = nil
			valid_insert_error(@log)
		end

		it "approval log insert failed: action_by is nil" do
			@log.action_by = nil
			valid_insert_error(@log)
		end

		it "approval log insert failed: approval_request_id is nil" do
			@log.approval_request_id = nil
			valid_insert_error(@log)
		end
	end
end