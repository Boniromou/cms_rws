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

module FundInOut
  class FundError < CageError
  end

  class AmountInvalidError < FundError
  end

  class CallWalletFail < FundError
  end

  class VoidTransactionNotExist < FundError
  end

  class AlreadyVoided <FundError
  end
end

module PlayerProfile
  class PlayerProfile < CageError
  end

  class PlayerNotFound < PlayerProfile
  end

  class PlayerNotActivated < PlayerProfile
    attr_reader :player
    def initialize(player)
      @player = player
    end
  end
end

module SearchPlayerTransaction
  class SearchPlayerTransactionError < CageError
  end

  class NoIdNumberError < SearchPlayerTransactionError
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

  class RetryError < RemoteError
  end

  class ReturnError < RemoteError
  end

  class RaiseError < RemoteError
  end

  class WalletError < ReturnError
  end

  class GetBalanceError < WalletError
  end

  class UnexpectedResponseFormat < RetryError
  end

  class CreatePlayerError < ReturnError
  end

  class DepositError < RaiseError
  end

  class WithdrawError < RaiseError
  end

  class AmountNotEnough < WithdrawError
  end

  class PlayerNotFound < RaiseError
  end

  class PinError < RaiseError
  end

  class InvalidTimeRange < RaiseError
  end

  class NoPinAuditLog < RaiseError
  end
end

module Search
  class SearchError < CageError
  end

  class OverRangeError < SearchError
  end

  class DateTimeError < SearchError
  end

  class NoResultException < SearchError
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
      super(400, 'Session token is invalid.', data)
    end
  end

  class InvalidLoginName < RequestError
    def initialize(data=nil)
      super(400, 'Login name is invalid.', data)
    end
  end

  class InvalidPin < RequestError
    def initialize(data=nil)
      super(400, 'Pin is wrong with card id', data)
    end
  end

  class InvalidMachineToken < RequestError
    def initialize(data=nil)
      super(400, 'Machine token is invalid', data)
    end
  end

  class InvalidCardId < RequestError
    def initialize(data=nil)
      super(400, 'Card id is not exist', data)
    end
  end

  class PlayerLocked < RequestError
    def initialize(data=nil)
      super(400, 'Player is locked', data)
    end
  end

  class RetrieveBalanceFail < RequestError
    def initialize(data=nil)
      super(500, 'Retrieve balance from wallet fail', data)
    end
  end
end
