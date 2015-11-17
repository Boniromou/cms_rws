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
    @root_user = User.create!(:uid => 1, :name => 'portal.admin')
    login_as(@root_user)
  end

  def login_as_admin_new
    Rails.cache.write '1', {:status => true, :admin => true}
    result = {'success' => true, 'system_user' => {'id' => 1, 'username' => 'portal.admin'}}
    UserManagement.stub(:authenticate).and_return(result)
    visit '/login'
    fill_in "user_username", :with => 'portal.admin'
    fill_in "user_password", :with => 'Cc123456'
    click_button I18n.t("general.login")
  end

  def login_as_not_admin(user)
    login_as user
    Rails.cache.write user.uid.to_s, {:status => true, :admin => false}
  end

  def login_as_admin
    @root_user = User.create!(:uid => 1, :name => 'portal.admin')
    login_as_not_admin(@root_user)
    Rails.cache.write @root_user.uid.to_s, {:status => true, :admin => true}
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

  def check_balance_page(balance = 0)
    check_title("tree_panel.balance")
    expect(find("label#player_balance").text).to eq to_display_amount_str(balance)
  end

  def check_balance_page_without_balance
    check_title("tree_panel.balance")
    expect(find("label#player_balance").text).to eq  I18n.t("balance_enquiry.no_balance")
  end

  def check_profile_page(balance = 0)
    check_title("tree_panel.profile")
    expect(find("label#player_balance").text).to eq to_display_amount_str(balance)
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
    expect(find("label#player_card_id").text).to eq @player.card_id.to_s
    if @player.status == 'active'
      expect(find("label#player_status").text).to eq I18n.t("player_status.#{@player.status}")
    else
      check_player_lock_types
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
    expect(page.source).to have_selector("input#accounting_date")
    # expect(page.source).to have_selector("select#shift_name")
  end

  def check_player_transaction_result_contents(item, player_transaction, reprint_granted, void_granted, reprint_void_granted)
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
    if player_transaction.void_transaction
      void_slip_number_str = player_transaction.void_transaction.slip_number.to_s
    else
      void_slip_number_str = ""
    end
    expect(item[0].text).to eq player_transaction.slip_number.to_s
    expect(item[1].text).to eq player.member_id
    expect(item[2].text).to eq accounting_date.accounting_date.strftime("%Y-%m-%d")
    expect(item[3].text).to eq player_transaction.created_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[4].text).to eq location
    expect(item[5].text).to eq user.name
    expect(item[6].text).to eq player_transaction.display_status
    expect(item[7].text).to eq deposit_str
    expect(item[8].text).to eq withdraw_str
    expect(item[9].text).to eq void_slip_number_str
    within item[10] do
      if player_transaction.status == 'completed'
        trans_type = player_transaction.transaction_type.name
        if reprint_granted
          expect(page.source).to have_selector("a#reprint")
        else
          expect(page.source).to_not have_selector("a#reprint")
        end
        if player_transaction.can_void?
          expect(page.source).to have_selector("button#void_#{trans_type}_#{player_transaction.id}") if void_granted
        else
          expect(page.source).to_not have_selector("button#void_#{trans_type}_#{player_transaction.id}")
          expect(page.source).to have_selector("a#reprint_void") if reprint_void_granted && player_transaction.voided?
        end
      end
    end
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
    expect(item[8].text).to eq withdraw_str
    expect(item[9].text).to eq to_display_amount_str(player_transaction.amount)
  end

  def check_ch_report_result_items(history_hash)
    items = all("table#datatable_col_reorder tr")
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
    expect(item[1].text).to eq change_history.action_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[2].text).to eq change_history.action
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
    expect(item[1].text).to eq change_history[:action_at]
    expect(item[2].text).to eq change_history[:action]
    expect(item[3].text).to eq change_history[:member_id]
  end

  def check_stations_table_items(station_list,permission_list)
    items = all("table#datatable_col_reorder tbody tr")
    expect(items.length).to eq station_list.length
    items.length.times do |i|
      expect(items[i][:id]).to eq "station_#{station_list[i].id}"
      within items[i] do
        check_stations_table_contents(all("td"),station_list[i],permission_list)
      end
    end
  end

  def check_stations_table_contents(item, station, permission_list)
    expect(item[0].text).to eq station.id.to_s
    expect(item[1].text).to eq station.location.name
    expect(item[2].text).to eq station.name
    expect(item[3].text).to eq station.terminal_id || ""
    expect(item[4].text).to eq station.updated_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    within item[5] do
      if permission_list[:change_status]
        expect(page.source).to have_selector("button#change_station_status_#{station.id}")
      end
      if permission_list[:register]
        btn_prefix = ""
        btn_prefix = "un" unless station.terminal_id.nil?
        expect(page.source).to have_selector("button##{btn_prefix}register_terminal_#{station.id}")
      end
    end
  end

  def click_pop_up_confirm(btn_id, content_list)
    find("div#button_set button##{btn_id}").click
    within ("div#pop_up_content") do
      content_list.each do |str|
        expect(page).to have_content str
      end
    end
    find("div#pop_up_dialog div#pop_up_confirm_btn button#confirm").trigger('click')
  end

  def set_terminal_id(terminal_id)
    visit page.current_url + "?terminal_id=" + terminal_id
  end

  def register_terminal
    @location5 = Location.create!(:name => "LOCATION5", :status => "active")
    @station5 = Station.create!(:name => "STATION5", :status => "active", :location_id => @location5.id)
    visit list_stations_path("active")
    content_list = [I18n.t("terminal_id.confirm_reg1"), I18n.t("terminal_id.confirm_reg2", name: @station5.full_name)]
    click_pop_up_confirm("register_terminal_" + @station5.id.to_s, content_list)

    check_flash_message I18n.t("terminal_id.register_success", station_name: @station5.full_name)
    @station5.reload
    expect(@station5.terminal_id).to_not eq nil
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
    find("button#confirm_fund_in").click
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
    find("button#confirm_fund_out").click
    expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true

    find("div#pop_up_dialog")[:class].include?("fadeIn").should == true
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
    transaction = PlayerTransaction.create!(:shift_id => target_transaction.shift_id, :player_id => target_transaction.player_id, :user_id => target_transaction.user_id, :transaction_type_id => target_transaction.transaction_type_id + 2, :status => "completed", :amount => target_transaction.amount, :station_id => target_transaction.station_id , :created_at => Time.now, :slip_number => target_transaction.slip_number + 1)
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

      expected_flash_message = I18n.t("#{@lock_or_unlock}_player.success", name: @player.full_name.upcase)

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

    @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :machine_token => @machine_token1, :created_at => Time.now, :slip_number => 1)
    @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 20000, :machine_token => @machine_token1, :created_at => Time.now + 30*60, :slip_number => 2)
    @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 30000, :machine_token => @machine_token2, :created_at => Time.now + 60*60, :slip_number => 3)
  end
end
RSpec.configure do |config|
  config.include StepHelper, type: :feature
end
