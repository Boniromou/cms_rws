require 'rails_helper'

RSpec.describe Approval::Internal::RequestsController, :type => :controller do
  describe 'submit' do
    before :each do
      @req1 = create(:request)
      @params = {use_route: :Approval}
      @params['target'] = 'jackpot'
      @params['target_id'] = 1000
      @params['approval_action'] = 'set_config'
      @params['data'] = {'num' => 1}
      @params['current_user'] = 'portal.admin@mo.laxino.com'
    end

    it 'approval request submit successfully' do
      post :submit, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'OK'
    end

    it 'approval request submit failed: exist ongoing request' do
      @params['target'] = @req1.target
      @params['target_id'] = @req1.target_id
      @params['approval_action'] = @req1.action
      post :submit, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'ApprovalSubmitFailed'
    end

    it 'approval request submit failed: target is nil' do
      @params['target'] = nil
      post :submit, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'StandardError'
    end
  end

  describe 'update_status' do
    before :each do
      @req1 = create(:request)
      @req2 = create(:request, :request_canceled)
      @params = {use_route: :Approval}
      @params['target'] = @req1.target
      @params['target_id'] = @req1.target_id
      @params['approval_action'] = @req1.action
      @params['operation'] = Approval::Request::APPROVE
      @params['current_user'] = 'portal.admin@mo.laxino.com'
    end

    it 'approval approve successfully' do
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'OK'
    end

    it 'approval publish successfully' do
      @req1.status = Approval::Request::APPROVED
      @req1.save
      @params['operation'] = Approval::Request::PUBLISH
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'OK'
    end

    it 'approval cancel successfully: status is pending' do
      @params['operation'] = Approval::Request::CANCEL
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'OK'
    end

    it 'approval cancel successfully: status is approved' do
      @req1.status = Approval::Request::APPROVED
      @req1.save
      @params['operation'] = Approval::Request::CANCEL
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'OK'
    end

    it 'approval update_status failed: undefined operation' do
      @params['operation'] = 'abc'
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'ApprovalUndefinedOperation'
    end

    it 'approval update_status failed: not exist ongoing request' do
      @params['target'] = @req2.target
      @params['target_id'] = @req2.target_id
      @params['approval_action'] = @req2.action
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'ApprovalNotExistRequest'
    end

    it 'approval update_status failed: current status can not approve' do
      @req1.status = Approval::Request::APPROVED
      @req1.save
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'ApprovalUpdateStatusFailed'
    end

    it 'approval update_status failed: current status can not publish' do
      @req1.status = Approval::Request::PENDING
      @req1.save
      @params['operation'] = Approval::Request::PUBLISH
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'ApprovalUpdateStatusFailed'
    end

    it 'approval update_status failed: current user is nil' do
      @params['current_user'] = nil
      post :update_status, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'StandardError'
    end
  end

  describe 'get_details' do
    before :each do
      @req1 = create(:request)
      @log1 = create(:log, :approval_request_id => @req1.id)

      @params = {use_route: :Approval}
      @params['target'] = @req1.target
      @params['target_id'] = @req1.target_id
      @params['approval_action'] = @req1.action
    end

    it 'approval get details successfully' do
      get :get_details, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'OK'
      expect(result['target']).to eq @req1.target
      expect(result['target_id']).to eq @req1.target_id
      expect(result['action']).to eq @req1.action
      expect(result['data']).to eq @req1.data
      expect(result['next_steps']).to eq [Approval::Request::APPROVE, Approval::Request::CANCEL]
      expect(result['request_logs'].size).to eq 1
    end
  end

  describe 'get_status_by_target_ids' do
    before :each do
      @req1 = create(:request)
      @req2 = create(:request, :status => Approval::Request::APPROVED)
      @params = {use_route: :Approval}
      @params['target'] = @req1.target
      @params['target_ids'] = [@req1.target_id, @req2.target_id]
      @params['approval_action'] = @req1.action
    end

    it 'approval get_status_by_target_ids successfully' do
      get :get_status_by_target_ids, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'OK'
      expect(result['response'].size).to eq 2
    end
  end

  describe 'get_details_by_target_ids' do
    before :each do
      @req1 = create(:request)
      @req2 = create(:request, :status => Approval::Request::APPROVED)
      @params = {use_route: :Approval}
      @params['target'] = @req1.target
      @params['target_ids'] = [@req1.target_id, @req2.target_id]
      @params['approval_action'] = @req1.action
    end

    it 'approval get_details_by_target_ids successfully' do
      get :get_details_by_target_ids, @params
      result = JSON.parse response.body
      expect(result['error_code']).to eq 'OK'
      expect(result['response'].size).to eq 2
    end
  end
end
