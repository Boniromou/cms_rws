class AccountActivityDatatable
  include FundHelper
  include FormattedTimeHelper

  def initialize(requester_factory, params)
    @wallet_requester = requester_factory.get_wallet_requester
    @params = params
  end

  def as_json(options = {})
    response = get_raw_records
    return fail_response unless response.success?
    {
      :draw => @params[:draw].to_i,
      :recordsTotal => response.total_count,
      :recordsFiltered => response.total_count,
      :data => format_data(response)
    }
  end

  private

  def get_raw_records
    @wallet_requester.get_account_activity(@params[:member_id], @params[:start_time], @params[:end_time], @params[:round_id], @params[:length], @params[:start], sort_column)
  end

  def format_data(response)
    transactions = get_transactions_detail(response.transactions)
    transactions.map do |trans|
      [
        format_time(trans['trans_date']),
        trans['trans_type'] ? trans['trans_type'].titleize : '',
        trans['casino_name'],
        trans['property_name'],
        format_zone_location(trans['machine_token']),
        trans['ref_trans_id'],
        trans['round_id'],
        trans['slip_number'],
        trans['employee_name'],
        trans['status'],
        display_balance(trans['cash_before_balance']),
        display_balance(trans['credit_before_balance']),
        display_balance(trans['cash_amt']),
        display_balance(trans['credit_amt']),
        display_balance(trans['cash_after_balance']),
        display_balance(trans['credit_after_balance'])
      ]
    end
  end

  def columns
    ['trans_date','trans_type','casino_name','property_name','machine_token','ref_trans_id','round_id','slip_number','employee_name','status','cash_before_balance','credit_before_balance','cash_amt','credit_amt','cash_after_balance','credit_after_balance']
  end

  def sort_column
    order = @params[:order].values.first
    "#{columns[order['column'].to_i]} #{order['dir']}"
  end

  def get_transactions_detail(transactions)
    ref_trans_ids = transactions.map {|trans| trans['ref_trans_id']}
    player_transactions = PlayerTransaction.includes(:transaction_type).where(ref_trans_id: ref_trans_ids).map { |trans| {"#{trans.ref_trans_id}_#{trans.transaction_type.name}" => trans.as_json} }.inject(:merge) || {}
    transactions.each do |trans|
      player_trans = player_transactions["#{trans['ref_trans_id']}_#{trans['trans_type']}"] || {}
      trans['slip_number'] = player_trans['slip_number']
    end
  end

  def fail_response
    {
      :draw => @params[:draw].to_i,
      :recordsTotal => 0,
      :recordsFiltered => 0,
      :data => [],
      :error_msg => I18n.t('account_activity.search_error')
    }
  end
end
