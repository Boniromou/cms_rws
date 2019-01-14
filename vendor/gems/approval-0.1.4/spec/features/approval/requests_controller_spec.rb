require 'rails_helper'

RSpec.describe Approval::RequestsController, :type => :feature do
  def mock_current_system_user
    allow_any_instance_of(ApplicationController).to receive(:current_system_user).and_return(SystemUser.new)
    allow_any_instance_of(SystemUser).to receive(:username_with_domain).and_return('test@laxino.com')
  end

  def mock_authorize
    allow_any_instance_of(ApplicationHelper).to receive(:policy).and_return(TestPolicy.new)
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(TestPolicy.new)
    allow_any_instance_of(TestPolicy).to receive("set_rtp_approval_list?".to_sym).and_return(true)
    allow_any_instance_of(TestPolicy).to receive("list_log?".to_sym).and_return(true)
    ['approve', 'cancel_submit', 'cancel_approve'].each do |operation|
      allow_any_instance_of(TestPolicy).to receive("set_rtp_#{operation}?".to_sym).and_return(true)
    end
  end

  before(:each) do
    mock_current_system_user
    mock_authorize
  end

  context '[1] approve' do
    before :each do
      @req = create(:request, :status => Approval::Request::PENDING)
      visit approval.index_path({target: @req.target, all: true, approval_action: @req.action})
    end

    scenario '[1.1] Successfully approve request' do
      find("#approve_#{@req.id}", visible: false).click
      expect(page).to have_content I18n.t('approval.success', operation: 'approve', approval_action: 'set rtp')
      @req.reload
      expect(@req.status).to eq Approval::Request::APPROVED
    end

    scenario '[1.2] Fail to approve request(request status is not pending)' do
      @req.update_attributes(status: Approval::Request::APPROVED)
      find("#approve_#{@req.id}", visible: false).click
      expect(page).to have_content I18n.t('approval.failed', operation: 'approve', approval_action: 'set rtp')
      @req.reload
      expect(@req.status).to eq Approval::Request::APPROVED
    end
  end

  context '[2] cancel submit' do
    before :each do
      @req = create(:request, :status => Approval::Request::PENDING)
      visit approval.index_path({target: @req.target, all: true, approval_action: @req.action})
    end

    scenario '[2.1] Successfully cancel submit request' do
      find("#cancel_submit_#{@req.id}", visible: false).click
      expect(page).to have_content I18n.t('approval.success', operation: 'cancel submit', approval_action: 'set rtp')
      @req.reload
      expect(@req.status).to eq Approval::Request::CANCELED
    end

    scenario '[2.2] Fail to cancel submit request(request status is not pending)' do
      @req.update_attributes(status: Approval::Request::CLOSED)
      find("#cancel_submit_#{@req.id}", visible: false).click
      expect(page).to have_content I18n.t('approval.failed', operation: 'cancel submit', approval_action: 'set rtp')
      @req.reload
      expect(@req.status).to eq Approval::Request::CLOSED
    end
  end

  context '[3] cancel approve' do
    before :each do
      @req = create(:request, :status => Approval::Request::APPROVED)
      visit approval.requests_approved_index_path({target: @req.target, all: true, approval_action: @req.action})
    end

    scenario '[3.1] Successfully cancel approve request' do
      find("#cancel_approve_#{@req.id}", visible: false).click
      expect(page).to have_content I18n.t('approval.success', operation: 'cancel approve', approval_action: 'set rtp')
      @req.reload
      expect(@req.status).to eq Approval::Request::CANCELED
    end

    scenario '[3.2] Fail to cancel approve request(request status is not approved)' do
      @req.update_attributes(status: Approval::Request::CLOSED)
      find("#cancel_approve_#{@req.id}", visible: false).click
      expect(page).to have_content I18n.t('approval.failed', operation: 'cancel approve', approval_action: 'set rtp')
      @req.reload
      expect(@req.status).to eq Approval::Request::CLOSED
    end
  end
end