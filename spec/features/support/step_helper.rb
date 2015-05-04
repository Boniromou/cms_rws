module StepHelper
  def check_flash_message(msg)
    flash_msg = find("div#flash_message div#message_content")
    expect(flash_msg.text).to eq(msg)
  end

  def login_as_root
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
    login_as(@root_user)
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
    @root_user_name = 'portal.admin'
    @root_user_password = '123456'

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
    within "div#content" do
    
      expect(page).to have_content @location
      begin
        expect(page).to have_content @accounting_date
      rescue RSpec::Expectations::ExpectationNotMetError => e
        expect(page).to have_content "Waiting for accounting date"
      end
      begin
        expect(page).to have_content I18n.t("shift.#{@shift}")
      rescue RSpec::Expectations::ExpectationNotMetError => e
        expect(page).to have_content "Waiting for shift"
      end
    end
  end

  def check_search_page
    check_title("tree_panel.balance")
    expect(page.source).to have_selector("input#id_number")
  end

  def check_not_found
    check_search_page
    expect(page.source).to have_content(I18n.t("search_error.not_found"))
  end

  def fill_search_info(id_type,id_number)
    choose I18n.t("general."+id_type)
    fill_in "id_number", :with => id_number
  end

  def fill_search_info_js(id_type,id_number)
    find("input##{id_type}").trigger('click')
    fill_in "id_number", :with => id_number
  end

  def check_balance_page
    check_title("tree_panel.balance")
    expect(find("label#player_balance").text).to eq to_display_amount_str(@player.balance)
  end

  def check_player_info
    expect(find("label#player_name").text).to eq @player.player_name
    expect(find("label#player_member_id").text).to eq @player.member_id.to_s
    expect(find("label#player_card_id").text).to eq @player.card_id.to_s
  end

  def check_player_transaction_page
    expect(find("input#card_id")[:checked]).to eq "checked"
    expect(find("input#datetimepicker_start_time").value).to eq Time.now.strftime("%Y-%m-%d 00:00:00")
    expect(find("input#datetimepicker_end_time").value).to eq Time.now.strftime("%Y-%m-%d 23:59:00")
  end

  def check_player_transaction_page_js
    expect(find("input#card_id")[:checked]).to eq true
    expect(find("input#datetimepicker_start_time").value).to eq Time.now.strftime("%Y-%m-%d 00:00:00")
    expect(find("input#datetimepicker_end_time").value).to eq Time.now.strftime("%Y-%m-%d 23:59:00")
  end

  def check_search_fm_page
    expect(page.source).to have_selector("input#accounting_date")
    expect(page.source).to have_selector("select#shift_name")
  end

  def check_player_transaction_result_contents(item, player_transaction, reprint_granted)
    player = Player.find(player_transaction.player_id)
    shift = Shift.find(player_transaction.shift_id)
    accounting_date = AccountingDate.find(shift.accounting_date_id)
    station = Station.find(player_transaction.station_id)
    user = User.find(player_transaction.user_id)
    if player_transaction.transaction_type_id == 1
      deposit_str = player_transaction.amount.to_s
      withdraw_str = ""
    else
      deposit_str = ""
      withdraw_str = player_transaction.amount.to_s
    end
    expect(item[0].text).to eq player_transaction.id.to_s
    expect(item[1].text).to eq player.player_name
    expect(item[2].text).to eq player.member_id
    expect(item[3].text).to eq accounting_date.accounting_date.strftime("%Y-%m-%d")
    expect(item[4].text).to eq player_transaction.created_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[5].text).to eq shift.name
    expect(item[6].text).to eq station.name
    expect(item[7].text).to eq user.employee_id
    expect(item[8].text).to eq player_transaction.status
    expect(item[9].text).to eq deposit_str
    expect(item[10].text).to eq withdraw_str
    within item[11] do
      if reprint_granted
        expect(page.source).to have_selector("input#reprint")
      else
        expect(page.source).to_not have_selector("input#reprint")
      end
    end
  end

  def check_player_transaction_result_items(transaction_list, reprint_granted = true)
    items = all("table#datatable_col_reorder tr")
    items.length.times do |i|
      expect(items[i][:id]).to eq "transaction_#{transaction_list[i].id}"
      within items[i] do
        check_player_transaction_result_contents(all("td"),transaction_list[i], reprint_granted)
      end
    end
  end

  def check_fm_remort_result_items(transaction_hash)
    items = all("table#datatable_col_reorder tr")
    i = 0
    transaction_hash.each do |k,v|
      total_deposit = 0
      total_withdraw = 0
      v.each do |t|
        within items[i] do
          expect(items[i][:id]).to eq "transaction_#{t.id}"
          check_fm_remort_result(all("td"),t)
        end
        if t.transaction_type_id == 1
          total_deposit += t.amount
        else
          total_withdraw += t.amount
        end
        i += 1
      end
      within items[i] do
        tds = all("td")
        expect(tds[1].text).to eq total_deposit.to_s
        expect(tds[2].text).to eq total_withdraw.to_s
      end
      i += 1
    end
  end

  def check_fm_remort_result(item, player_transaction)
    player = Player.find(player_transaction.player_id)
    shift = Shift.find(player_transaction.shift_id)
    accounting_date = AccountingDate.find(shift.accounting_date_id)
    station = Station.find(player_transaction.station_id)
    user = User.find(player_transaction.user_id)
    if player_transaction.transaction_type_id == 1
      deposit_str = player_transaction.amount.to_s
      withdraw_str = ""
    else
      deposit_str = ""
      withdraw_str = player_transaction.amount.to_s
    end
    expect(item[0].text).to eq player_transaction.id.to_s
    expect(item[1].text).to eq player.player_name
    expect(item[2].text).to eq player.member_id
    expect(item[3].text).to eq accounting_date.accounting_date.strftime("%Y-%m-%d")
    expect(item[4].text).to eq player_transaction.created_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[5].text).to eq shift.name
    expect(item[6].text).to eq station.name
    expect(item[7].text).to eq user.employee_id
    expect(item[8].text).to eq player_transaction.status
    expect(item[9].text).to eq deposit_str
    expect(item[10].text).to eq withdraw_str
    expect(item[11].text).to eq player_transaction.amount.to_s
  end
end

RSpec.configure do |config|
  config.include StepHelper, type: :feature
end
