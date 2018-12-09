class PlayerBalanceReportDatatable < AjaxDatatablesRails::Base
  def_delegators :@view, :link_to, :content_tag, :h, :mailto, :edit_resource_path, :other_method

  include AjaxDatatablesRails::Extensions::Kaminari
  include FundHelper

  def sortable_columns
    # list columns inside the Array in string dot notation.
    # Example: 'users.email'
    @sortable_columns ||= ['players.member_id', 'players.status']
  end

  def searchable_columns
    # list columns inside the Array in string dot notation.
    # Example: 'users.email'
    @searchable_columns ||= ['players.member_id', 'players.status']
  end

  private

  def data
    balances = get_player_balances(records.map(&:member_id)) if records.size > 0
    records.map do |record|
      [
        record.member_id,
        record.status.titleize,
        record.active_lock_types.map{|lock_type| lock_type.name }.join(','),
        balances[record.member_id]
      ]
    end
  end

  def get_raw_records
    Player.includes(:active_lock_types).where(licensee_id: options[:licensee_id])
  end

  def get_player_balances(login_names)
    result = options[:wallet_requester].get_player_balances(login_names)
    Hash[result.players.map{|player| [player['login_name'], display_balance(player['balance'])]}]
  end
end
