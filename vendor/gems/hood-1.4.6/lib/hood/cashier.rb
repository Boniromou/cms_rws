require 'singleton'

module Hood
  class Cashier
    include Singleton
    include Loggable

    def update(inbound)
      @inbound = inbound
      begin
        event_name = inbound[:_event_name].to_sym
        @outbound = self.__send__("process_#{event_name}_event") || {}
      rescue HoodError => e
        log_exception(e)
        @outbound = e.to_hash
      end
      if @outbound[:error_code].nil?
        @outbound.merge!({:status=>200,:error_code=>'OK',:error_msg=>'Request is carried out successfully.'})
      end
      @outbound
    end

    def process_create_player_event
      ParamUtil.ensure_params_given(@inbound,:property_id,:login_name,:currency)
      preprocess_basic_params
      @inbound[:shareholder] = @inbound[:vendor] if @inbound[:vendor]
      Player.create_or_check_account(@inbound[:property_id],@inbound[:login_name],@inbound[:currency],@inbound[:shareholder])
      {}
    end

    def process_create_internal_player_event
      ParamUtil.ensure_params_given(@inbound, :property_id, :login_name, :currency, :player_id, :player_currency_id)
      preprocess_basic_params
      @inbound[:shareholder] = @inbound[:vendor] if @inbound[:vendor]
      Player.create_or_check_internal_account(@inbound[:property_id], @inbound[:login_name], @inbound[:currency], @inbound[:shareholder], @inbound[:player_id], @inbound[:player_currency_id])
      {}
    end

    def process_query_player_balance_event
      ParamUtil.ensure_params_given(@inbound,:property_id,:login_name)
      preprocess_basic_params
      res = Player.query_balance(@inbound[:property_id],@inbound[:login_name])
      if res[:credit_is_expired]
        process_transaction_event(CreditAutoExpireTransaction)
        res = Player.query_balance(@inbound[:property_id],@inbound[:login_name])
      end
      res
    end
    
    def process_query_player_balances_event
      ParamUtil.ensure_params_given(@inbound,:property_id,:login_names)
      preprocess_basic_params
      login_names = @inbound[:login_names]
      if login_names.is_a? String
        login_names = login_names.downcase.split(',')
      end
      raise BadRequest.new unless login_names.is_a? Array
      Player.query_balances(@inbound[:property_id],login_names)
    end

    def process_query_vendor_total_balance_event
      #ParamUtil.ensure_params_given(@inbound,:property_id,:vendor)
      ParamUtil.ensure_params_given(@inbound,:property_id)
      Player.query_vendor_total_balance(@inbound[:property_id],@inbound[:vendor])
    end

    def process_deposit_event
      ParamUtil.ensure_params_given(@inbound,*(trans_required_params + [:amt]))
      preprocess_cashier_cash_transaction_params
      process_transaction_event(DepositTransaction)
    end

    def process_withdraw_event
      ParamUtil.ensure_params_given(@inbound,*(trans_required_params + [:amt]))
      preprocess_cashier_cash_transaction_params
      process_transaction_event(WithdrawTransaction)
    end

    def process_void_deposit_event
      ParamUtil.ensure_params_given(@inbound,*(trans_required_params + [:amt]))
      preprocess_cashier_cash_transaction_params
      process_transaction_event(VoidDepositTransaction)
    end

    def process_void_withdraw_event
      ParamUtil.ensure_params_given(@inbound,*(trans_required_params + [:amt]))
      preprocess_cashier_cash_transaction_params
      process_transaction_event(VoidWithdrawTransaction)
    end

    def process_credit_deposit_event
      ParamUtil.ensure_params_given(@inbound,*(trans_required_params + [:credit_amt,:credit_expired_at]))
      preprocess_cashier_credit_transaction_params
      ParamUtil.ensure_params_given(@inbound,:credit_expired_at)
      process_transaction_event(CreditDepositTransaction)
    end

    def process_credit_expire_event
      ParamUtil.ensure_params_given(@inbound,*(trans_required_params + [:credit_amt]))
      preprocess_cashier_credit_transaction_params
      process_transaction_event(CreditExpireTransaction)
    end

    def process_credit_auto_expire_event
      ParamUtil.ensure_params_given(@inbound,:property_id,:login_name)
      process_transaction_event(CreditAutoExpireTransaction)
    end

    def process_bet_event
      ParamUtil.ensure_params_given(@inbound,*(round_trans_required_params+[:bet_amt]))
      preprocess_round_transaction_params
      ParamUtil.amt_dollar_to_cent(@inbound,:bet_amt)
      ParamUtil.ensure_amt_positive(@inbound,:bet_amt)
      process_transaction_event(BetTransaction)
    end

    def process_cancel_bet_event
      ParamUtil.ensure_params_given(@inbound,*(round_trans_required_params+[:bet_amt]))
      preprocess_round_transaction_params
      ParamUtil.amt_dollar_to_cent(@inbound,:bet_amt)
      ParamUtil.ensure_amt_positive(@inbound,:bet_amt)
      process_transaction_event(CancelBetTransaction)
    end

    def process_result_event
      ParamUtil.ensure_params_given(@inbound,*(round_trans_required_params+[:payout_amt,:win_amt,:total_bet_amt]))
      preprocess_round_transaction_params
      ParamUtil.amt_dollar_to_cent(@inbound,:payout_amt,:win_amt,:total_bet_amt)
      ParamUtil.ensure_amt_nonnegative(@inbound,:payout_amt)
      preprocess_jp_params
      process_transaction_event(ResultTransaction)
    end

    def process_query_system_time_event
      ParamUtil.ensure_params_given(@inbound,:property_id)
      time_zone = Property.get_time_zone(@inbound[:property_id])
      {:time => TimeUtil.to_local_str(Time.now - 1,time_zone)}
    end

    def process_query_cashier_transactions_event
      ParamUtil.ensure_params_given(@inbound,:property_id,:from_time,:to_time)
      CashierTransaction.query_transactions(@inbound[:property_id],@inbound[:from_time],@inbound[:to_time])
    end

    def process_query_result_transactions_event
      ParamUtil.ensure_params_given(@inbound,:property_id,:from_time,:to_time)
      RoundTransaction.query_result_transactions(@inbound[:property_id],@inbound[:from_time],@inbound[:to_time])
    end

    protected
    def process_transaction_event(cls)
      Player.lock(@inbound[:property_id],@inbound[:login_name]) do |player|
        if player.credit_expired? && cls != CreditAutoExpireTransaction
          begin
            CreditAutoExpireTransaction.process(player,{:property_id=>@inbound[:property_id],:login_name=>@inbound[:login_name]})
          rescue
            raise InternalError.new
          end
        end
        cls.process(player,@inbound)
      end
    end
    
    def preprocess_cashier_cash_transaction_params
      ParamUtil.amt_dollar_to_cent(@inbound,:amt)
      ParamUtil.ensure_amt_positive(@inbound,:amt)
      preprocess_basic_params
    end

    def preprocess_cashier_credit_transaction_params
      ParamUtil.amt_dollar_to_cent(@inbound,:credit_amt)
      ParamUtil.ensure_amt_positive(@inbound,:credit_amt)
      preprocess_basic_params
    end

    def preprocess_round_transaction_params
      preprocess_basic_params
      @inbound[:external_game_id] = @inbound.delete(:game_id) if @inbound[:game_id]
      ParamUtil.to_i(@inbound,:internal_game_id,:external_game_id,:round_id)
    end

    def preprocess_basic_params
      ParamUtil.to_i(@inbound,:property_id)
      ParamUtil.downcase(@inbound,:login_name)
    end

    def trans_required_params
      [:property_id,:login_name,:ref_trans_id]
    end

    def round_trans_required_params
      trans_required_params + [:round_id,:internal_game_id,:game_id,:session_token,:trans_date]
    end
    
    def preprocess_jp_params
      jp_params = [:jc_jp_con_amt,:jc_jp_win_amt,:pc_jp_con_amt,:pc_jp_win_amt,:jp_win_id,:jp_win_lev,:jp_direct_pay]
      missing_params = []
      jp_params.each do |name|
        @inbound[name] = nil if @inbound[name] == ""
        missing_params.push(name.to_s) unless @inbound[name]
      end
      if missing_params.size>0
        if @inbound[:jc_jp_con_amt] && @inbound[:pc_jp_con_amt]
          if missing_params.size==jp_params.size-2 # no win, only jc_jp_con_amt and pc_jp_con_amt
            #
          else
            raise MissingRequiredParameters.new(missing_params)
          end
        else
          raise MissingRequiredParameters.new(missing_params) unless missing_params.size==jp_params.size
        end
      else
        ParamUtil.to_i(@inbound,:jp_win_lev,:jp_direct_pay)
      end
    end

  end
end

