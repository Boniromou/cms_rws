module StepHelper
  @root_user_name = 'portal.admin'
  @root_user_password = '123456'
 
  def check_flash_message(msg)
    flash_msg = find("div#flash_message div#message_content")
    expect(flash_msg.text).to eq(msg)
  end

  def login_as_root
    root_user = User.find_by_uid(1)
    login_as(root_user)
  end
=begin
  def login_as(user)
    Rails.cache.write user.uid.to_s, {:status => true, :admin => true}
    result = {'success' => true, 'system_user' => {'id' => user.uid, 'username' => user.employee_id}}
    UserManagement.stub(:authenticate).and_return(result)
    visit '/login'
    fill_in "user_username", :with => user.employee_id
    fill_in "user_password", :with => 'secret'
    click_button I18n.t("general.login")
  end
=end
  def login_as_not_admin(user)
    login_as user
    Rails.cache.write user.uid.to_s, {:status => true, :admin => false}
  end

  def login_as_admin
    allow(UserManagement).to receive(:authenticate).and_return({'success' => true, 'system_user' => {'username' => @root_user_name, 'id' => 1}})
    allow_any_instance_of(ApplicationPolicy).to receive(:is_admin?).and_return(true)

    visit login_path
    fill_in "user_username", with: @root_user_name
    fill_in "user_password", with: @root_user_password
    click_button I18n.t("general.login")
  end

  def set_permission(user,role,target,permissions)
    cache_key = "#{APP_NAME}:permissions:#{user.uid}"
    origin_permissions = Rails.cache.fetch cache_key
    origin_perm_hash = origin_permissions[:permissions][:permissions]
    perm_hash = origin_perm_hash.merge({target => permissions})
    permission = {:permissions => {:role => role, :permissions => perm_hash}}
    Rails.cache.write cache_key,permission
  end    

  def check_complete_success_audit
    al = AuditLog.first
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("update")
    expect(al.action).to eq("complete")
    expect(al.action_status).to eq("success")
    expect(al.action_error).to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_complete_fail_audit
    al = AuditLog.first
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("update")
    expect(al.action).to eq("complete")
    expect(al.action_status).to eq("fail")
    expect(al.action_error).not_to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_reschedule_success_audit
    al = AuditLog.first	
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("update")
    expect(al.action).to eq("reschedule")
    expect(al.action_status).to eq("success")
    expect(al.action_error).to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_reschedule_fail_audit
    al = AuditLog.first
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("update")
    expect(al.action).to eq("reschedule")
    expect(al.action_status).to eq("fail")
    expect(al.action_error).not_to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_create_success_audit
    al = AuditLog.first
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("create")
    expect(al.action).to eq("create")
    expect(al.action_status).to eq("success")
    expect(al.action_error).to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_create_fail_audit
  end

  def check_extend_success_audit
    al = AuditLog.first
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("update")
    expect(al.action).to eq("extend")
    expect(al.action_status).to eq("success")
    expect(al.action_error).to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_extend_fail_audit
    al = AuditLog.first
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("update")
    expect(al.action).to eq("extend")
    expect(al.action_status).to eq("fail")
    expect(al.action_error).not_to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_cancel_success_audit
    al = AuditLog.first
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("update")
    expect(al.action).to eq("cancel")
    expect(al.action_status).to eq("success")
    expect(al.action_error).to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_cancel_fail_audit
    al = AuditLog.first
    expect(al.audit_target).to eq("maintenance")
    expect(al.action_type).to eq("update")
    expect(al.action).to eq("cancel")
    expect(al.action_status).to eq("fail")
    expect(al.action_error).not_to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq("portal.admin")
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to be_nil
  end

  def check_success_audit_log(audit_target, action_type, action, action_by, description=nil)
    al = AuditLog.first
    expect(al.audit_target).to eq audit_target
    expect(al.action_type).to eq action_type
    expect(al.action).to eq action
    expect(al.action_status).to eq("success")
    expect(al.action_error).to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq action_by
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to eq description
  end

  def check_fail_audit_log(audit_target, action_type, action, action_by, description=nil)
    al = AuditLog.first
    expect(al.audit_target).to eq audit_target
    expect(al.action_type).to eq action_type
    expect(al.action).to eq action
    expect(al.action_status).to eq("fail")
    expect(al.action_error).not_to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq action_by
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to eq description
  end

  def click_add_test_player_btn_with_login_name(login_name)
    add_test_player_row_selector = "div#content div#test_players_content tbody tr:last-child"
    test_player_input_field_selector = "#{add_test_player_row_selector} td:first-child input"
    add_test_btn_selector = "#{add_test_player_row_selector} td:last-child button"
    find(test_player_input_field_selector).set login_name
    find(add_test_btn_selector).click
  end

  def check_change_history(action, action_by, change_detail, object, property_id)
    ch = ChangeHistory.first
    expect(ch.action).to eq action
    expect(ch.action_by).to eq action_by
    expect(ch.change_detail).to eq change_detail
    expect(ch.object).to eq object
    expect(ch.property_id).to eq property_id
    expect(ch.created_at).to_not be_nil
  end

  def verify_propagation_table(ppg_id, propagation_status_to_expect)
    propagation_table_selector = "div#content div#test_players_content div.jarviswidget"
    propagation_table_header = find("#{propagation_table_selector} header:first-child")
    propagation_first_row_selector = "#{propagation_table_selector} table tbody tr:first-child"
    propagation_first_row_id = find("#{propagation_first_row_selector} td:first-child")
    propagation_first_row_status = find("#{propagation_first_row_selector} td:nth-child(3)")
    #propagation_first_row_error = find("#{propagation_first_row_selector} td:nth-child(4)")
    #propagation_first_row_operation = find("#{propagation_first_row_selector} td:nth-child(5)")
    expect(propagation_table_header.text).to eq I18n.t("propagation.title")
    expect(propagation_first_row_id.text).to eq ppg_id
    expect(propagation_first_row_status.text).to eq propagation_status_to_expect
  end

  def check_title(title_str)
    title = first("div div h1")
    expect(title.text).to eq I18n.t(title_str)
  end

  def check_home_page
    expect(page).to have_content @location
    expect(page).to have_content @accounting_date
    expect(page).to have_content @shift.capitalize
  end
end

RSpec.configure do |config|
  config.include StepHelper, type: :feature
end
