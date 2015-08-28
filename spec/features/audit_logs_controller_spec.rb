require "feature_spec_helper"
include ActionView::Helpers::FormOptionsHelper

describe AuditLogsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    User.delete_all
    Warden.test_reset!
  end
  
  def go_to_search_audit_log
    click_header_link(I18n.t("header.audit_log"))
    click_link('Search Audit Log')
  end
  
  describe '[13] Search audit log' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "player", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :created_at => "2014-09-29 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
      @al2 = AuditLog.new({ :audit_target => "player", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :created_at => "2014-09-30 12:00:00", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al2.save(:validate => false)
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[13.1] Search audit log by time' do
      login_as_admin
      visit '/search_audit_logs'
      fill_in "from", :with => "2014-9-29"
      fill_in "to", :with => "2014-9-29"
      click_button I18n.t("button.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).not_to have_selector("tr#audit#{@al2.id}_body")
    end
  end
  
  describe '[13] Search audit log' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "player", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :created_at => Time.now.utc, :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
      @al2 = AuditLog.new({ :audit_target => "player", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "ray.chan", :created_at => Time.now.utc, :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al2.save(:validate => false)
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[13.2] search audit log by actioner' do
      login_as_admin
      visit '/search_audit_logs'
      fill_in "action_by", :with => "portal.admin"
      click_button I18n.t("button.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).not_to have_selector("tr#audit#{@al2.id}_body")
    end
    
    it '[13.3] search empty in actioner' do
      login_as_admin
      visit '/search_audit_logs'
      click_button I18n.t("button.search")
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).to have_selector("tr#audit#{@al2.id}_body")
    end
  end
  
  describe '[13] Search audit log' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "player", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :created_at => Time.now.utc, :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
      @al2 = AuditLog.new({ :audit_target => "player", :action_type => "update", :action_error => "", :action => "edit", :action_status => "success", :action_by => "portal.admin", :created_at => Time.now.utc, :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al2.save(:validate => false)
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[13.4] search audit log by action', :js => true do
      login_as_admin
      visit '/search_audit_logs'
      select("Player", :from => "target_name")
      select "All", :from => "action_list"
      click_button I18n.t("button.search")
      wait_for_ajax
      @al1.reload
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
    end
    
    it '[13.5] search all action' do
      login_as_admin
      visit '/search_audit_logs'
      select "All", :from => "target_name"
      select "All", :from => "action_list"
      click_button I18n.t("button.search")
      @al1.reload
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).to have_selector("tr#audit#{@al2.id}_body")
    end
  end

  describe '[13] Search audit log' do
    before(:each) do
      AuditLog.delete_all
      @al1 = AuditLog.new({ :audit_target => "player", :action_type => "create", :action_error => "", :action => "create", :action_status => "success", :action_by => "portal.admin", :created_at => Time.now.utc, :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al1.save(:validate => false)
      @al2 = AuditLog.new({ :audit_target => "system_user", :action_type => "update", :action_error => "", :action => "lock", :action_status => "success", :action_by => "portal.admin", :created_at => "2014-09-29 12:00:01", :session_id => "qwer1234", :ip => "127.0.0.1", :description => "" })
      @al2.save(:validate => false)
    end
    
    after(:each) do
      AuditLog.delete_all
    end
    
    it '[13.6] search audit log by target' do
      login_as_admin
      visit '/search_audit_logs'
      select "Player", :from => "target_name"
      click_button I18n.t("button.search")
      @al1.reload
      expect(page.source).to have_selector("tr#audit#{@al1.id}_body")
      expect(page.source).not_to have_selector("tr#audit#{@al2.id}_body")
    end
  end
end
