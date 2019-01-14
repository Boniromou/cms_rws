require "rails_helper"

describe "ApprovalRequestSpec" do
	describe "submit" do
		before :each do
			@req1 = create(:request)
	    @req2 = create(:request, :request_approved)
	    @req3 = create(:request, :request_canceled)
	    @req4 = create(:request, :request_closed)
			@current_user = "portal.admin@mo.laxino.com"
		end

		def valid_submit_success(req)
			req_count = Approval::Request.count
			log_count = Approval::Log.count
			Approval::Request.submit(req.target, req.target_id, req.action, {}, @current_user)
			expect(Approval::Request.count).to eq req_count + 1
			expect(Approval::Log.count).to eq log_count + 1
		end

		def valid_submit_failed(req, error, current_user=@current_user)
			req_count = Approval::Request.count
			log_count = Approval::Log.count
			flag = false
			begin
				Approval::Request.submit(req.target, req.target_id, req.action, {}, current_user)
			rescue error.constantize
				flag = true
			end
			expect(flag).to eq true
			expect(Approval::Request.count).to eq req_count
			expect(Approval::Log.count).to eq log_count
		end

		it "approval request submit successfully" do
			req_count = Approval::Request.count
			log_count = Approval::Log.count
			target = "jackpot"
			target_id = 1
			action = "set_config"
			data = {:num => 1}
			Approval::Request.submit(target, target_id, action, data, @current_user)
			expect(Approval::Request.count).to eq req_count + 1
			expect(Approval::Log.count).to eq log_count + 1

			request = Approval::Request.where(:target => target, :target_id => target_id, :action => action).first
			expect(request).not_to be_nil
			expect(request.status).to eq Approval::Request::PENDING
			expect(request.data.recursive_symbolize_keys).to eq data

			logs = request.logs
			expect(logs.size).to eq 1
			expect(logs[0].action).to eq Approval::Request::SUBMIT
			expect(logs[0].action_by).to eq @current_user
		end

		it "approval request submit successfully: exist canceled request" do
			valid_submit_success(@req3)
		end

		it "approval request submit successfully: exist closed request" do
			valid_submit_success(@req4)
		end

		it "approval request submit failed: exist pending request" do
			valid_submit_failed(@req1, "Approval::ApprovalSubmitFailed")
		end

		it "approval request submit failed: exist approved request" do
			valid_submit_failed(@req2, "Approval::ApprovalSubmitFailed")
		end

		it "approval request submit failed: target is nil" do
			@req3.target = nil
			valid_submit_failed(@req3, "ActiveRecord::RecordInvalid")
		end

		it "approval request submit failed: target_id is nil" do
			@req3.target_id = nil
			valid_submit_failed(@req3, "ActiveRecord::RecordInvalid")
		end

		it "approval request submit failed: action is nil" do
			@req3.action = nil
			valid_submit_failed(@req3, "ActiveRecord::RecordInvalid")
		end

		it "approval request submit failed: current_user is nil" do
			valid_submit_failed(@req3, "ActiveRecord::RecordInvalid", nil)
		end
	end

	describe "update status" do
		before :each do
			@req1 = create(:request)
	    @req2 = create(:request, :request_approved)
	    @req3 = create(:request, :request_canceled)
	    @req4 = create(:request, :request_closed)
			@current_user = "portal.admin@mo.laxino.com"
		end

		def valid_update_success(req, operation, status)
			log_count = Approval::Log.count
			Approval::Request.update_status(req.target, req.target_id, req.action, operation, @current_user)
			expect(Approval::Log.count).to eq log_count + 1

			request = Approval::Request.find(req.id)
			expect(request.status).to eq status

			logs = request.logs
			expect(logs.size).to eq 1
			expect(logs[0].action).to eq operation
			expect(logs[0].action_by).to eq @current_user
		end

		def valid_update_failed(req, operation, error, current_user=@current_user)
			log_count = Approval::Log.count
			flag = false
			begin
				Approval::Request.update_status(req.target, req.target_id, req.action, operation, current_user)
			rescue error.constantize
				flag = true
			end
			expect(flag).to eq true
			expect(Approval::Log.count).to eq log_count
		end

		it "approval update status failed: undefined operation" do
			valid_update_failed(@req1, "error_operation", "Approval::ApprovalUndefinedOperation")
		end

		it "approval update status failed: not exist ongoing request" do
			valid_update_failed(@req3, Approval::Request::APPROVE, "Approval::ApprovalNotExistRequest")
			valid_update_failed(@req4, Approval::Request::APPROVE, "Approval::ApprovalNotExistRequest")
		end

		it "approval update status failed: current_user is nil" do
			valid_update_failed(@req1, Approval::Request::APPROVE, "ActiveRecord::RecordInvalid", nil)
		end

		it "approval request approve successfully" do
			valid_update_success(@req1, Approval::Request::APPROVE, Approval::Request::APPROVED)
		end

		it "approval request approve failed: status is not pending" do
			valid_update_failed(@req2, Approval::Request::APPROVE, "Approval::ApprovalUpdateStatusFailed")
		end

		it "approval request publish successfully" do
			valid_update_success(@req2, Approval::Request::PUBLISH, Approval::Request::CLOSED)
		end

		it "approval request publish failed: status is not approved" do
			valid_update_failed(@req1, Approval::Request::PUBLISH, "Approval::ApprovalUpdateStatusFailed")
		end

		it "approval request cancel successfully: status is pending" do
			valid_update_success(@req1, Approval::Request::CANCEL, Approval::Request::CANCELED)
		end

		it "approval request cancel successfully: status is approved" do
			valid_update_success(@req2, Approval::Request::CANCEL, Approval::Request::CANCELED)
		end
	end

	describe "get_details" do
		before :each do
			@req1 = create(:request)
	    @req2 = create(:request, :request_approved)
	    @req3 = create(:request, :request_canceled)
	    @req4 = create(:request, :request_closed)
	    @req5 = create(:request, :request_canceled, :target100)
	    @req6 = create(:request, :request_closed, :target100)
	    @req7 = create(:request, :target100)

	    @log1 = create(:log, :approval_request_id => @req1.id)
	    @log2 = create(:log, :approval_request_id => @req2.id)
	    @log3 = create(:log, :log_approve, :approval_request_id => @req2.id)
	    @log4 = create(:log, :approval_request_id => @req3.id)
	    @log5 = create(:log, :log_cancel, :approval_request_id => @req3.id)
	    @log6 = create(:log, :approval_request_id => @req4.id)
	    @log7 = create(:log, :log_approve, :approval_request_id => @req4.id)
	    @log8 = create(:log, :log_publish, :approval_request_id => @req4.id)
	    @log9 = create(:log, :approval_request_id => @req5.id)
	    @log10 = create(:log, :log_cancel, :approval_request_id => @req5.id)
	    @log11 = create(:log, :approval_request_id => @req6.id)
	    @log12 = create(:log, :log_approve, :approval_request_id => @req6.id)
	    @log13 = create(:log, :log_publish, :approval_request_id => @req6.id)
	    @log14 = create(:log, :approval_request_id => @req7.id)
	  end

	  def valid_details(result, req, next_steps)
	  	expect(result[:id]).to eq req.id
			expect(result[:target]).to eq req.target
			expect(result[:target_id]).to eq req.target_id
			expect(result[:action]).to eq req.action
			expect(result[:data]).to eq req.data.recursive_symbolize_keys
			expect(result[:status]).to eq req.status
			expect(result[:next_steps]).to eq next_steps
	  end

	  def valid_deatil_logs(result, logs)
	  	expect(result.size).to eq logs.size
	  	result.each_with_index do |log, index|
				expect(log[:action]).to eq logs[index].action
				expect(log[:action_by]).to eq logs[index].action_by
			end
	  end

		it "get details successfully: status is pending" do
			result = Approval::Request.get_details(@req1.target, @req1.target_id, @req1.action)
			valid_details(result, @req1, [Approval::Request::APPROVE, Approval::Request::CANCEL])
			valid_deatil_logs(result[:request_logs], [@log1])
		end

		it "get details successfully: status is pending, had canceled, closed approval reqquest" do
			result = Approval::Request.get_details(@req7.target, @req7.target_id, @req7.action)
			valid_details(result, @req7, [Approval::Request::APPROVE, Approval::Request::CANCEL])
			valid_deatil_logs(result[:request_logs], [@log14])
		end

		it "get details successfully: status is approved" do
			result = Approval::Request.get_details(@req2.target, @req2.target_id, @req2.action)
			valid_details(result, @req2, [Approval::Request::PUBLISH, Approval::Request::CANCEL])
			valid_deatil_logs(result[:request_logs], [@log2, @log3])
		end

		it "get details successfully: status is cancel" do
			result = Approval::Request.get_details(@req3.target, @req3.target_id, @req3.action)
			valid_details(result, @req3, [Approval::Request::SUBMIT])
			valid_deatil_logs(result[:request_logs], [@log4, @log5])
		end

		it "get details successfully: status is closed" do
			result = Approval::Request.get_details(@req4.target, @req4.target_id, @req4.action)
			valid_details(result, @req4, [Approval::Request::SUBMIT])
			valid_deatil_logs(result[:request_logs], [@log6, @log7, @log8])
		end
	end

	describe "get_status_by_target_ids" do
		before :each do
	    @req1 = create(:request, :request_canceled, :target100)
	    @req2 = create(:request, :request_closed, :target100)
	    @req3 = create(:request, :target100)
	    @req4 = create(:request, :request_approved)
	    @req5 = create(:request, :request_closed)
	    @req6 = create(:request, :request_canceled)
	  end

	  it "get_status_by_target_ids successfully" do
	  	target_ids = [@req3.target_id, @req4.target_id, @req5.target_id, @req6.target_id]
	  	response = Approval::Request.get_status_by_target_ids(@req1.target, target_ids, @req1.action)
	  	expect(response.size).to eq 2
	  	expect(response[@req3.target_id]).to eq @req3.status
	  	expect(response[@req4.target_id]).to eq @req4.status
	  end

	  it "get_status_by_target_ids successfully: result is empty" do
	  	target_ids = [1000, 1001]
	  	response = Approval::Request.get_status_by_target_ids(@req1.target, target_ids, @req1.action)
	  	expect(response).to eq({})
	  end
	end

	describe "get_details_by_target_ids" do
		def format_result(req)
			req.as_json.merge(req.data).slice!('data').recursive_symbolize_keys
		end

		before :each do
	    @req1 = create(:request, :request_canceled, :target100)
	    @req2 = create(:request, :request_closed, :target100)
	    @req3 = create(:request, :target100)
	    @req4 = create(:request, :request_approved)
	    @req5 = create(:request, :request_closed)
	    @req6 = create(:request, :request_canceled)
	  end

	  it "get_details_by_target_ids successfully" do
	  	target_ids = [@req3.target_id, @req4.target_id, @req5.target_id, @req6.target_id]
	  	response = Approval::Request.get_details_by_target_ids(@req1.target, target_ids, @req1.action)
	  	expect(response.size).to eq 2
	  	expect(response[@req3.target_id].to_s).to eq format_result(@req3).to_s
	  	expect(response[@req4.target_id].to_s).to eq format_result(@req4).to_s
	  end

	  it "get_details_by_target_ids successfully: result is empty" do
	  	target_ids = [1000, 1001]
	  	response = Approval::Request.get_details_by_target_ids(@req1.target, target_ids, @req1.action)
	  	expect(response).to eq({})
	  end
	end
end
