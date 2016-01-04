module Requester
  class Response
    def initialize(result_hash)
      @result_hash = result_hash
    end

    def error_code
      @result_hash[:error_code].to_s
    end

    def error_msg
      @result_hash[:error_msg].to_s || "no message"
    end

    def exception_msg
      "error_code #{error_code}: #{error_msg}"
    end

    def success?
      ['OK'].include?(error_code)
    end
  end

  class WalletResponse < Response
  end

  class WalletTransactionResponse < WalletResponse
    def trans_date
      @result_hash[:trans_date]
    end

    def success?
      ['OK','AlreadyProcessed'].include?(error_code)
    end
    
    def amount_not_enough?
      ['AmountNotEnough'].include?(error_code)
    end
    
    def credit_not_expired?
      ['CreditNotExpired'].include?(error_code)
    end

    def amount_not_match?
      ['AmountNotMatch'].include?(error_code)
    end

    def balance
      @result_hash[:balance].to_f if @result_hash[:balance]
    end
  end
end
