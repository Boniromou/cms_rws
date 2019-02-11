module TransactionAdapter

  def deposit_amt_str
    result = ""
    result = to_display_amount_str(amount) if self.transaction_type.name == self.class::DEPOSIT
    result
  end

  def withdraw_amt_str
    result = ""
    result = to_display_amount_str(amount) if self.transaction_type.name == self.class::WITHDRAW
    result
  end

  def slip_number
    ''
  end

  def location
    self.kiosk_name
  end

  def user
    User.new(:name => kiosk_name)
  end
  
  def approved_by
    ''
  end
  
  def payment_method_id
    nil
  end
  
  def source_of_fund_id
    nil
  end

  def data
    ''
  end
  
  def data_hash
    {}
  end

  def void_transaction
    nil
  end
  
  def voided?
    display_status == 'voided'
  end

  def can_void?
    false
  end
end
