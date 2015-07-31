module StepHelper
  include ActionView::Helpers
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
    expect(find("label#player_status").text).to eq I18n.t("player_status.#{@player.status}")
  end

  def check_player_transaction_page_time_picker
    expect(find("input#datetimepicker_start_time").value).to eq Time.now.strftime("%Y-%m-%d 00:00:00")
    expect(find("input#datetimepicker_end_time").value).to eq Time.now.strftime("%Y-%m-%d 23:59:59")
  end

  def check_player_transaction_page
    expect(find("input#card_id")[:checked]).to eq "checked"
    check_player_transaction_page_time_picker
  end

  def check_player_transaction_page_js
    expect(find("input#card_id")[:checked]).to eq true
    check_player_transaction_page_time_picker
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
      deposit_str = to_display_amount_str(player_transaction.amount)
      withdraw_str = ""
    else
      deposit_str = ""
      withdraw_str = to_display_amount_str(player_transaction.amount)
    end
    expect(item[0].text).to eq player_transaction.id.to_s
    expect(item[1].text).to eq player.full_name.upcase
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
    items = all("table#datatable_col_reorder tbody tr")
    expect(items.length).to eq transaction_list.length
    items.length.times do |i|
      expect(items[i][:id]).to eq "transaction_#{transaction_list[i].id}"
      within items[i] do
        check_player_transaction_result_contents(all("td"),transaction_list[i], reprint_granted)
      end
    end
  end

  def check_fm_report_result_items(transaction_hash)
    items = all("table#datatable_col_reorder tr")
    i = 1
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
#      within items[i] do
#        tds = all("td")
#        expect(tds[1].text).to eq to_display_amount_str(total_deposit)
#        expect(tds[2].text).to eq to_display_amount_str(total_withdraw)
#      end
#      i += 1
    end
  end


  def check_fm_remort_result(item, player_transaction)
    player = Player.find(player_transaction.player_id)
    shift = Shift.find(player_transaction.shift_id)
    accounting_date = AccountingDate.find(shift.accounting_date_id)
    station = Station.find(player_transaction.station_id)
    user = User.find(player_transaction.user_id)
    if player_transaction.transaction_type_id == 1
      deposit_str = to_display_amount_str(player_transaction.amount)
      withdraw_str = ""
    else
      deposit_str = ""
      withdraw_str = to_display_amount_str(player_transaction.amount)
    end
    expect(item[0].text).to eq player_transaction.id.to_s
    expect(item[1].text).to eq player.full_name.upcase
    expect(item[2].text).to eq player.member_id
    expect(item[3].text).to eq accounting_date.accounting_date.strftime("%Y-%m-%d")
    expect(item[4].text).to eq player_transaction.created_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    expect(item[5].text).to eq shift.name
    expect(item[6].text).to eq station.name
    expect(item[7].text).to eq user.employee_id
    expect(item[8].text).to eq player_transaction.status
    expect(item[9].text).to eq deposit_str
    expect(item[10].text).to eq withdraw_str
    expect(item[11].text).to eq to_display_amount_str(player_transaction.amount)
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
    expect(item[3].text).to eq station.machine_id || ""
    expect(item[4].text).to eq station.updated_at.localtime.strftime("%Y-%m-%d %H:%M:%S")
    within item[5] do
      if permission_list[:change_status]
        expect(page.source).to have_selector("button#change_station_status_#{station.id}")
      end
      if permission_list[:register]
        btn_prefix = ""
        btn_prefix = "un" unless station.machine_id.nil?
        expect(page.source).to have_selector("button##{btn_prefix}register_machine_#{station.id}")
      end
    end
  end
end
RSpec.configure do |config|
  config.include StepHelper, type: :feature
end
