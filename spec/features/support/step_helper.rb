#require 'spec_helper'

module StepHelper
  include ActionView::Helpers
  def check_flash_message(msg)
    flash_msg = find("div#flash_message div#message_content")
    expect(flash_msg.text).to eq(msg)
  end

  def check_location_name(name)
    location_name = find("div#location_name")
    expect(location_name.text).to eq (name)
  end

  def login_as_root
    @root_user = User.create!(:uid => 1, :name => 'portal.admin', :casino_id => 20000)
    login_as(@root_user)
  end

  def login_as_admin_new
    Rails.cache.write '1', {:status => true, :admin => true, :casinos => [20000]}
    result = {'success' => true, 'system_user' => {'id' => 1, 'username' => 'portal.admin'}}
    allow(UserManagement).to receive(:authenticate).and_return(result)
    visit '/login'
    fill_in "user_username", :with => 'portal.admin'
    fill_in "user_password", :with => 'Cc123456'
    click_button I18n.t("general.login")
  end

  def login_as_not_admin(user)
    login_as user

    #page.set_rack_session( :casino_info => Casino.find_by_id(20000).name)
    #page.set_rack_session( :machine_token => '20000|1|01|4|0102|2|abc1234|6e80a295eeff4554bf025098cca6eb37')

    Rails.cache.write user.uid.to_s, {:status => true, :admin => false,  :casinos => [20000]}
  end

  def login_as_admin(casino_id = 20000)
#    @root_user = User.create!(:uid => 1, :name => 'portal.admin', :casino_id => casino_id)
    @root_user = User.create!(:uid => 1, :name => 'portal.admin')
    login_as_not_admin(@root_user)
    Rails.cache.write @root_user.uid.to_s, {:status => true, :admin => true, :properties => [20000], :casinos => [20000]}
    
  end

  def login_as_admin_multi_casino(casino_id = 20000)
  #not finish
    login_as_admin
    Rails.cache.write @root_user.uid.to_s, {:status => true, :admin => true, :properties => [20000], :casinos => [20000, 1003]}
  end

  def login_as_test_user
    @test_user = User.create!(:uid => 2, :name => 'test.user')
    login_as_not_admin(@test_user)
  end

  def set_permission(user,role,target,permissions)
    permission_mapping = {#player
                          :balance => 'balance_enquiry',
                          :profile => 'player_profile',
                          #player_transaction
                          :search => 'transaction_history', 
                          :reprint => 'reprint_slip', 
                          :print => 'print_slip',
                          :print_void => 'print_void_slip',
                          :reprint_void => 'reprint_void_slip',
                          :print_report => 'print_transaction_report',
                          #shift
                          :search_fm => 'fm_activity_report',
                          :print_fm => 'print_fm_activity_report'
                          }
    cache_key = "#{APP_NAME}:permissions:#{user.uid}"
    permissions.each_index do |i|
      permissions[i] = permission_mapping[permissions[i].to_sym] || permissions[i]
    end
    origin_permissions = Rails.cache.fetch cache_key
    if origin_permissions.nil?
      origin_perm_hash = {}
    else
      origin_perm_hash = origin_permissions[:permissions][:permissions]
    end
    perm_hash = origin_perm_hash.merge({target => permissions})
    permission = {:permissions => {:role => role, :permissions => perm_hash}}
    Rails.cache.write cache_key,permission
  end    


  def check_title(title_str)
    title = first("div div h2")
    expect(title.text).to include I18n.t(title_str)
  end

  def check_home_page
    within "div#content" do
    
      expect(page).to have_content @location
      begin
        expect(page).to have_content @accounting_date
      rescue RSpec::Expectations::ExpectationNotMetError => e
        expect(page).to have_content "Waiting for accounting date"
      end
      # begin
      #   expect(page).to have_content I18n.t("shift.#{@shift}")
      # rescue RSpec::Expectations::ExpectationNotMetError => e
      #   expect(page).to have_content "Waiting for shift"
      # end
    end
  end

  def check_search_page(title = "balance")
    check_title("tree_panel.#{title}")
    expect(page.source).to have_selector("input#card_id")
    expect(page.source).to have_selector("input#member_id")
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

  def check_balance_page(balance = 0, credit_balance = nil, expired_at = nil)
    check_title("tree_panel.balance")
    check_balance_amount(balance,credit_balance, expired_at)
    check_remain_amount(:deposit, :withdraw)
  end

  def check_balance_page_without_balance
    check_title("tree_panel.balance")
    expect(find("label#player_balance").text).to eq  I18n.t("balance_enquiry.no_balance")
  end

  def check_profile_page(balance = 0, credit_balance = nil, expired_at = nil)
    check_title("tree_panel.profile")
    check_balance_amount(balance,credit_balance,expired_at)
    check_remain_amount(:deposit, :withdraw)
  end

  def check_balance_amount(balance,credit_balance,expired_at)
    expect(find("label#player_balance").text).to eq to_display_amount_str(balance)
    expect(find("label#credit_balance").text).to eq to_display_amount_str(credit_balance) unless credit_balance.nil?
    expect(find("label#credit_expired_at").text).to eq expired_at unless expired_at.blank?
  end

  def check_remain_amount(*params)
    [:deposit, :withdraw].each do |trans_type|
      if params.include?(trans_type)
        str = to_display_amount_str(@player.trans_amount(trans_type, 20000))
        str += " #{to_display_amount_str(@player.remain_trans_amount(trans_type, 20000)).to_s}" if @player.remain_trans_amount(trans_type, 20000) <= 0
        expect(find("label#player_remain_#{trans_type}").text).to eq str
      else
        expect(page.source).to_not have_selector "label#player_remain_#{trans_type}"
      end
    end
  end

  def check_edit_page
    check_title("tree_panel.edit")
    expect(page.source).to have_selector("input#player_card_id")
    expect(page.source).to have_selector("input#player_first_name")
    expect(page.source).to have_selector("input#player_last_name")
  end

  def check_player_info
    expect(find("label#player_full_name").text).to eq @player.full_name.upcase
    expect(find("label#player_member_id").text).to eq @player.member_id.to_s
    expect(find("label#player_card_id").text).to eq @player.card_id.to_s.gsub(/(\d{4})(?=\d)/, '\\1-')
    if @player.status == 'active'
      expect(find("label#player_status").text).to eq I18n.t("player_status.#{@player.status}")
    else
      check_player_lock_types
    end
    if @player.test_mode_player
      expect(find("label#player_test_mode").text).to eq I18n.t("player_status.test_mode")
    else
      expect(page.source).to_not have_selector("label#player_test_mode")
    end
  end

  def check_player_lock_types
    @player.lock_types.each do |lock_type|
      expect(find("label#player_#{lock_type}").text).to eq I18n.t("player_status.#{lock_type}")
    end
  end

  def check_player_transaction_page_time_picker
    expect(find("input#datetimepicker_start_time").value).to eq Time.now.strftime("%Y-%m-%d 00:00:00")
    expect(find("input#datetimepicker_end_time").value).to eq Time.now.strftime("%Y-%m-%d 23:59:59")
  end

  def check_player_transaction_page_time_range_picker
    expect(find("input#start").value).to eq @accounting_date
    expect(find("input#end").value).to eq @accounting_date
  end

  def check_player_transaction_page
    expect(find("input#card_id")[:checked]).to eq "checked"
    check_player_transaction_page_time_range_picker
  end

  def check_player_transaction_page_js
    expect(find("input#card_id")[:checked]).to eq true
    check_player_transaction_page_time_range_picker
  end

  def check_search_fm_page
    expect(page.source).to have_selector("input#accounting_date")
    # expect(page.source).to have_selector("select#shift_name")
  end

  def check_search_ch_page
    expect(find("input#start").value).to eq @accounting_date
    expect(find("input#end").value).to eq @accounting_date
  end

  def check_player_transaction_result_contents(item, player_transaction, reprint_granted, void_granted, reprint_void_granted)
    player = Player.find(player_transaction.player_id)
    shift = Shift.find(player_transaction.shift_id)
    accounting_date = AccountingDate.find(shift.accounting_date_id)
    location = player_transaction.location
    user = player_transaction.user
    if player_transaction.transaction_type_id == 1
      deposit_str = to_display_amount_str(player_transaction.amount)
      withdraw_str = ""
    else
      deposit_str = ""
      withdraw_str = to_display_amount_str(player_transaction.amount)
    end
    if player_transaction.void_transaction
      void_slip_number_str = player_transaction.void_transaction.slip_number.to_s
    else
      void_slip_number_str = ""
    end
    i = 0
    expect(item[i].text).to eq player_transaction.source_type.gsub('_transaction','').titleize
    i +=1
    expect(item[i].text).to eq "MockUp"
    i +=1
    expect(item[i].text).to eq player_transaction.slip_number.to_s
    i +=1
    expect(item[i].text).to eq player.member_id
    i +=1
    expect(item[i].text).to eq accounting_date.accounting_date.strftime("%Y-%m-%d")
    i +=1
    expect(item[i].text).to eq player_transaction.created_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    i +=1
    expect(item[i].text).to eq location
    i +=1
    expect(item[i].text).to eq user.name
    i +=1
    expect(item[i].text).to eq player_transaction.display_status
    i +=1
    expect(item[i].text).to eq deposit_str
    i +=1
    expect(item[i].text).to eq player_transaction.data_hash[:deposit_reason].to_s
    i +=1
    expect(item[i].text).to eq withdraw_str
    i +=1
    expect(item[i].text).to eq void_slip_number_str
    i +=1
    within item[i] do
      if player_transaction.source_type == 'cage_transaction'
        if player_transaction.status == 'completed'
          trans_type = player_transaction.transaction_type.name
          if reprint_granted
            expect(item[i]).to have_selector("a#reprint")
          else
            expect(item[i]).to_not have_selector("a#reprint")
          end
          if player_transaction.can_void?
            expect(item[i]).to have_selector("button#void_#{trans_type}_#{player_transaction.id}") if void_granted
          else
            expect(item[i]).to_not have_selector("button#void_#{trans_type}_#{player_transaction.id}")
            expect(item[i]).to have_selector("a#reprint_void") if reprint_void_granted && player_transaction.voided?
          end
        end
      else
        expect(item[i]).to_not have_selector("a#reprint")
        expect(item[i]).to_not have_selector("button#void_#{trans_type}_#{player_transaction.id}")
        expect(item[i]).to_not have_selector("a#reprint_void")
      end
    end
  end

  def check_credit_transaction_result_contents(item, player_transaction)
    player = Player.find(player_transaction.player_id)
    shift = Shift.find(player_transaction.shift_id)
    accounting_date = AccountingDate.find(shift.accounting_date_id)
    location = player_transaction.location
    user = User.find(player_transaction.user_id)
    if player_transaction.transaction_type_id == 5
      credit_deposit_str = to_display_amount_str(player_transaction.amount)
      credit_expire_str = ""
      credit_expire_duration_str = player_transaction.data_hash[:duration].to_s
    else
      credit_deposit_str = ""
      credit_expire_str = to_display_amount_str(player_transaction.amount)
      credit_expire_duration_str = ""
    end
    expect(item[0].text).to eq player.member_id
    expect(item[1].text).to eq "MockUp"
    expect(item[2].text).to eq accounting_date.accounting_date.strftime("%Y-%m-%d")
    expect(item[3].text).to eq player_transaction.created_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[4].text).to eq location
    expect(item[5].text).to eq user.name
    expect(item[6].text).to eq player_transaction.display_status
    expect(item[7].text).to eq I18n.t("transaction_history.#{player_transaction.transaction_type.name}")
    expect(item[8].text).to eq credit_deposit_str
    expect(item[9].text).to eq credit_expire_str
    expect(item[10].text).to eq credit_expire_duration_str
    expect(item[11].text).to eq YAML.load(player_transaction.data)[:remark]
  end

  def check_player_transaction_result_items(transaction_list, reprint_granted = true, void_granted = true, reprint_void_granted = true)
    items = all("table#datatable_col_reorder tbody tr")
    expect(items.length).to eq transaction_list.length
    items.length.times do |i|
      expect(items[i][:id]).to eq "transaction_#{transaction_list[i].id}"
      within items[i] do
        check_player_transaction_result_contents(all("td"),transaction_list[i], reprint_granted, void_granted, reprint_void_granted)
      end
    end
  end

  def check_credit_transaction_result_items(transaction_list)
    items = all("table#datatable_col_reorder tbody tr")
    expect(items.length).to eq transaction_list.length

    items.length.times do |i|
      expect(items[i][:id]).to eq "transaction_#{transaction_list[i].id}"
      within items[i] do
        check_credit_transaction_result_contents(all("td"),transaction_list[i])
      end
    end
  end

  def check_fm_report_result_items(transaction_list)
    items = all("table#datatable_col_reorder tbody tr")
    expect(items.length).to eq transaction_list.length

    items.length.times do |i|
      expect(items[i][:id]).to eq "transaction_#{transaction_list[i].id}"
      within items[i] do
        check_fm_report_result_contents(all("td"),transaction_list[i])
      end
    end
  end

  def check_fm_report_result_contents(item, player_transaction)
    player = Player.find(player_transaction.player_id)
    shift = Shift.find(player_transaction.shift_id)
    accounting_date = AccountingDate.find(shift.accounting_date_id)
    location = player_transaction.location
    user = User.find(player_transaction.user_id)
    if player_transaction.transaction_type_id == 1
      deposit_str = to_display_amount_str(player_transaction.amount)
      withdraw_str = ""
    else
      deposit_str = ""
      withdraw_str = to_display_amount_str(player_transaction.amount)
    end
    expect(item[0].text).to eq player_transaction.slip_number.to_s
    expect(item[1].text).to eq player.member_id
    expect(item[2].text).to eq accounting_date.accounting_date.strftime("%Y-%m-%d")
    expect(item[3].text).to eq player_transaction.created_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[4].text).to eq location
    expect(item[5].text).to eq user.name
    expect(item[6].text).to eq player_transaction.status
    expect(item[7].text).to eq deposit_str
    expect(item[8].text).to eq player_transaction.data_hash[:deposit_reason].to_s
    expect(item[9].text).to eq withdraw_str
    expect(item[10].text).to eq to_display_amount_str(player_transaction.amount)
  end

  def check_ch_report_result_items(history_hash)
    items = all("table#datatable_col_reorder tr")
    expect(items.length - 1).to eq history_hash.length
    i = 1
    history_hash.each do |t|
      within items[i] do
        expect(items[i][:id]).to eq "history_#{t.id}"
        check_ch_report_result(all("td"),t)
      end
      i += 1
    end
  end

  def check_ch_report_result(item, change_history)
    expect(item[0].text).to eq change_history.action_by
    expect(item[0].find("a")['data-content'.to_sym]).to eq Casino.find_by_id(change_history.casino_id).name
    expect(item[1].text).to eq change_history.action_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[2].text).to eq I18n.t("change_history.#{change_history.action}")
    expect(item[3].text).to eq 'Member ID: ' + @player.member_id.to_s
  end

  def check_ph_report_result_items(history_hash)
    items = all("table#datatable_col_reorder tr")
    i = 1
    history_hash.each do |t|
      within items[i] do
        check_ph_report_result(all("td"),t)
      end
      i += 1
    end
  end

  def check_ph_report_result(item, change_history)
    expect(item[0].text).to eq change_history[:user]
    expect(item[0].find("a")['data-content'.to_sym]).to eq Casino.find_by_id(change_history[:casino_id]).name
    expect(item[1].text).to eq Time.parse(change_history[:action_at] + " UTC").localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[2].text).to eq I18n.t("pin_history.#{change_history[:action]}")
    expect(item[3].text).to eq change_history[:member_id]
  end


  def click_pop_up_confirm(btn_id, content_list)
    find("div#button_set button##{btn_id}").trigger('click')
    within ("div#pop_up_content") do
      content_list.each do |str|
        expect(page).to have_content str
      end
    end
    yield if block_given?
    find("div#pop_up_dialog div#pop_up_confirm_btn button#confirm").trigger('click')
  end

  def go_to_balance_enquiry_page
    begin
      find_link(I18n.t("tree_panel.balance"))
    rescue Capybara::ElementNotFound
      visit home_path
    end
    click_link I18n.t("tree_panel.balance")
    fill_search_info_js("member_id", @player.member_id)
    find("#button_find").click
    wait_for_ajax
    check_balance_page
  end

  def go_to_deposit_page
    begin
      find_link(I18n.t("tree_panel.balance"))
    rescue Capybara::ElementNotFound
      visit home_path
    end
    click_link I18n.t("tree_panel.balance")
    fill_search_info_js("member_id", @player.member_id)
    find("#button_find").click
    wait_for_ajax
    check_balance_page

    within "div#content" do
        click_link I18n.t("button.deposit")
    end
  end

  def go_to_credit_deposit_page
    begin
      find_link(I18n.t("tree_panel.balance"))
    rescue Capybara::ElementNotFound
      visit home_path
    end
    click_link I18n.t("tree_panel.balance")
    fill_search_info_js("member_id", @player.member_id)
    find("#button_find").click
    wait_for_ajax
    check_balance_page
    
    within "div#content" do
        click_link I18n.t("button.credit_deposit")
    end
  end

  def go_to_credit_expire_page
    begin
      find_link(I18n.t("tree_panel.balance"))
    rescue Capybara::ElementNotFound
      visit home_path
    end
    click_link I18n.t("tree_panel.balance")
    fill_search_info_js("member_id", @player.member_id)
    find("#button_find").click
    wait_for_ajax
    check_balance_page
    
    within "div#content" do
        click_link I18n.t("button.credit_expire")
    end
  end

  def go_to_withdraw_page
    begin
      find_link(I18n.t("tree_panel.balance"))
    rescue Capybara::ElementNotFound
      visit home_path
    end
    click_link I18n.t("tree_panel.balance")
    fill_search_info_js("member_id", @player.member_id)
    find("#button_find").click
    wait_for_ajax

    within "div#content" do
        click_link I18n.t("button.withdrawal")
    end
  end

  def do_deposit(amount)
    go_to_deposit_page
    wait_for_ajax
    fill_in "player_transaction_amount", :with => amount
    find("button#confirm_deposit").click
    expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
    
    expect(find("#fund_amt").text).to eq to_display_amount_str(amount * 100)
    expect(page).to have_selector("div#pop_up_dialog div button#confirm")
    expect(page).to have_selector("div#pop_up_dialog div button#cancel")
    find("div#pop_up_dialog div button#confirm").click
    wait_for_ajax

    PlayerTransaction.last
  end

  def do_withdraw(amount)
    go_to_withdraw_page
    wait_for_ajax
    fill_in "player_transaction_amount", :with => amount
    find("button#confirm_withdraw").click
    expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true

    expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
    expect(find("#fund_amt").text).to eq to_display_amount_str(amount * 100)
    expect(page).to have_selector("div#pop_up_dialog div button#confirm")
    expect(page).to have_selector("div#pop_up_dialog div button#cancel")
    find("div#pop_up_dialog div button#confirm").click
    wait_for_ajax
    PlayerTransaction.last
  end

  def do_void(transaction_id)
    player_transaction = PlayerTransaction.find(transaction_id)
    click_link I18n.t("tree_panel.player_transaction")
    check_player_transaction_page_js

    fill_in "slip_number", :with => player_transaction.slip_number
    find("input#selected_tab_index").set "1"

    find("input#search").click
    wait_for_ajax
    content_list = [I18n.t("confirm_box.void_transaction", slip_number: player_transaction.slip_number.to_s)]
    click_pop_up_confirm("void_#{player_transaction.transaction_type.name}_" + player_transaction.id.to_s, content_list)
    wait_for_ajax

    check_flash_message I18n.t("void_transaction.success", slip_number: player_transaction.slip_number.to_s)
    PlayerTransaction.last
  end

  def create_void_transaction(transaction_id)
    target_transaction = PlayerTransaction.find(transaction_id)
    transaction = PlayerTransaction.create!(:shift_id => target_transaction.shift_id, :player_id => target_transaction.player_id, :user_id => target_transaction.user_id, :transaction_type_id => target_transaction.transaction_type_id + 2, :status => "completed", :amount => target_transaction.amount, :machine_token => target_transaction.machine_token , :created_at => Time.now, :slip_number => target_transaction.slip_number + 1, :ref_trans_id => target_transaction.ref_trans_id, :casino_id => 20000)
  end

  def reset_slip_number
    TransactionSlip.all.each do |s|
      s.next_number = 1
      s.save
    end
  end

  def lock_or_unlock_player_and_check
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      wait_for_ajax

      check_search_page("profile")

      search_player_profile
      toggle_player_lock_status_and_check
  end

  def search_player_profile
      fill_search_info_js("card_id", @player.card_id)
      find("#button_find").click
      wait_for_ajax
  end

  def toggle_player_lock_status_and_check
      check_lock_unlock_page

      click_button I18n.t("button.#{@lock_or_unlock}")
      expect(find("div#pop_up_dialog")[:style]).to_not include "none"

      expected_flash_message = I18n.t("#{@lock_or_unlock}_player.success", name: @player.member_id)

      click_button I18n.t("button.confirm")
      wait_for_ajax

      check_lock_unlock_page
      check_flash_message expected_flash_message
  end

  def check_lock_unlock_page
      @player.reload
      update_lock_or_unlock

      check_profile_page
      check_player_info
      check_lock_unlock_components
  end

  def update_lock_or_unlock
      if @player.status == 'active'
        @lock_or_unlock = "lock"
      else
        @lock_or_unlock = "unlock"
      end
  end

  def check_lock_unlock_components
      expect(page).to have_selector "div#pop_up_dialog"
      expect(find("div#pop_up_dialog")[:style]).to include "none"
  end

  def create_player_transaction
    @machine_token1 = '20000|1|LOCATION1|1|STATION1|1|machine1|6e80a295eeff4554bf025098cca6eb37'
    @machine_token2 = '20000|2|LOCATION2|2|STATION2|2|machine2|6e80a295eeff4554bf025098cca6eb38'

    @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :machine_token => @machine_token1, :created_at => Time.now, :slip_number => 1, :casino_id => 20000)
    @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 20000, :machine_token => @machine_token1, :created_at => Time.now + 30*60, :slip_number => 2, :casino_id => 20000)
    @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 30000, :machine_token => @machine_token2, :created_at => Time.now + 60*60, :slip_number => 3, :casino_id => 20000)
  end

  def create_credit_transaction
    @machine_token1 = '20000|1|LOCATION1|1|STATION1|1|machine1|6e80a295eeff4554bf025098cca6eb37'
    @machine_token2 = '20000|2|LOCATION2|2|STATION2|2|machine2|6e80a295eeff4554bf025098cca6eb38'

    @credit_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 5, :status => "completed", :amount => 10000, :machine_token => @machine_token1, :created_at => Time.now, :data => {:remark => 'test1', :duration => 0.5}.to_yaml, :casino_id => 20000)
    @credit_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 5, :status => "completed", :amount => 20000, :machine_token => @machine_token1, :created_at => Time.now + 30*60, :data => {:remark => 'test2', :duration => 3}.to_yaml, :casino_id => 20000)
    @credit_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 6, :status => "completed", :amount => 30000, :machine_token => @machine_token2, :created_at => Time.now + 60*60, :data => {:remark => 'test3'}.to_yaml, :casino_id => 20000)
  end

  def check_credit_transaction(credit_transaction, transaction_type_name, status, amount, remark, duration= 0.5)
    expect(credit_transaction).not_to be_nil
    expect(credit_transaction.transaction_type.name).to eq transaction_type_name
    expect(credit_transaction.status).to eq status
    expect(credit_transaction.amount).to eq amount
    expect(YAML.load(credit_transaction.data)[:remark]).to eq remark
    expect(YAML.load(credit_transaction.data)[:duration]).to eq duration if credit_transaction.transaction_type.name == 'credit_deposit'
  end

  def create_default_player(*params)
    player_data = {:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 2, :status => "active", :licensee_id => 20000}
    options = params.extract_options!
    options.each do |k,v|
      player_data[k] = v
    end
    Player.create!(player_data)
  end
end

RSpec.configure do |config|
  config.include StepHelper, type: :feature
end
