class CageError < StandardError
end

module CreatePlayer
  class CreatePlayerError < CageError
  end

  class DuplicatedFieldError < CreatePlayerError
  end

  class ParamsError < CreatePlayerError
  end
end

module SearchPlayerTransaction
  class SearchPlayerTransactionError < CageError
  end

  class OverRangeError < SearchPlayerTransactionError
  end

  class DateTimeError < SearchPlayerTransactionError
  end

  class NoIdNumberError < SearchPlayerTransactionError
  end

  class NoResultException < SearchPlayerTransactionError
  end
end

module DatetimeParse
  class DatetimeParseError < CageError
  end

  class FormatError < DatetimeParseError
  end
end


module LocationError
  class AddLocationError < CageError
  end

  class AlreadyExistedError < AddLocationError
  end

  class CantBlankError < AddLocationError
  end
  
  class ChangeStatusError < CageError
  end

  class DisableFailError < ChangeStatusError
  end

  class DuplicatedChangeStatusError < ChangeStatusError
  end
end

module StationError
  class CreateStationError < CageError
  end

  class DuplicatedFieldError < CreateStationError
  end

  class ParamsError < CreateStationError
  end

  class InvalidLocationError < CreateStationError
  end
  
  class EnableStationError < CageError
  end

  class AlreadyEnabledError < EnableStationError
  end
  
  class EnableFailError < EnableStationError
  end

  class RegisterError < CageError
  end

  class StationAlreadyRegisterError < RegisterError
  end

  class TerminalAlreadyRegisterError < RegisterError
  end
  
  class StationAlreadyUnregisterError < RegisterError
  end

end

module Remote
  class RemoteError < CageError
  end

  class WalletError < RemoteError
  end

  class GetBalanceError < WalletError
  end

  class UnexpectedResponseFormat < RemoteError
  end

  class CreatePlayerError < RemoteError
  end

  class DepositError < RemoteError
  end

  class WithdrawError < RemoteError
  end

  class AmountNotEnough < WithdrawError
  end

  class LockPlayerError < RemoteError
  end

  class UnlockPlayerError < RemoteError
  end
end

module Request
  class RequestError < CageError
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
        :error_msg => @error_msg
        }.merge!(@data)
    end
  end

  class InvalidSessionToken < RequestError
    def initialize(data=nil)
      super(400,'Session token is invalid.',data)
    end
  end
end
