module Hood
  class HoodError < StandardError
    def initialize(status_code=500, error_msg=nil, data={})
      @status_code = status_code
      @error_msg = error_msg
      @data = data
    end

    def error_code
      self.class.name.split('::').last
    end

    def to_hash
      @data = {} unless @data
      { :status => @status_code ,
        :error_code => error_code,
        :message => @error_msg
        }.merge!(@data)
    end
  end

  class OKError < HoodError
    def initialize(msg=nil,data=nil)
      super(200,msg,data)
    end
  end

  class AlreadyProcessed < OKError
    def initialize(data=nil)
      super('The transaction has been already processed',data)
    end
  end

  class AlreadyCreated < OKError
  end

  class BadRequest < HoodError
    def initialize(msg=nil,data=nil)
      super(400,msg,data)
    end
  end

  class MissingRequiredParameters < BadRequest
    def initialize(missing_params,data=nil)
      msg = "Require Parameters: #{missing_params.join(', ')}"
      super(msg,data)
    end
  end

  class InternalError < HoodError
    def initialize(msg=nil,data=nil)
      super(500,msg,data)
    end
  end

  class NotImplementedError < InternalError
    def initialize(method_name)
      super(500,"#{method_name}# is not implemented")
    end
  end

  class InvalidAmount < BadRequest
  end

  class InvalidLoginName < BadRequest
  end

  class InvalidTimeRange < BadRequest
  end

  class AmountNotEnough < BadRequest
    def initialize(data=nil)
      super('balance amount is not enough',data)
    end
  end

  class FrozenPlayer < BadRequest
  end

  class CancelFundInNotExist < BadRequest
  end

  class CancelFundInNotMatch < BadRequest
  end

  class DuplicateTrans < BadRequest
  end

  class DuplicateTransWithSameValue < BadRequest
  end

  class CancelBetNotExist < BadRequest
  end

  class CancelBetNotMatch < BadRequest
  end

  class AlreadyCancelled < BadRequest
    def initialize(data=nil)
      super('The transaction has been already cancelled',data)
    end
  end

  class CurrencyNotSupport < BadRequest
  end

  class CurrencyNotMatch < BadRequest
  end

  class VendorNotMatch < BadRequest
  end

end
