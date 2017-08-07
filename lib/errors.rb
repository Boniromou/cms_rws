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

  class AlreadyVoided < FundError
  end

  class PlayerLocked <FundError
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

module Remote
  class RemoteError < CageError
    def initialize(result = nil)
      @result = result
    end

    def result
      @result || self.message
    end
  end

  class RetryError < RemoteError
  end

  class ReturnError < RemoteError
  end

  class RaiseError < RemoteError
  end

  class GetBalanceError < ReturnError
  end

  class NoBalanceError < GetBalanceError
  end

  class UnexpectedResponseFormat < RetryError
  end

  class CreatePlayerError < ReturnError
  end

  class CallWalletError < RaiseError
  end

  class DepositError < CallWalletError
  end

  class WithdrawError < CallWalletError
  end

  class AmountNotEnough < WithdrawError
  end

  class CreditDepositError < CallWalletError
  end

  class CreditNotExpired < CreditDepositError
  end

  class CreditExpireError < CallWalletError
  end
  
  class AmountNotMatch < CreditExpireError
  end
  
  class PlayerNotFound < RaiseError
  end

  class PinError < RaiseError
  end

  class InvalidTimeRange < RaiseError
  end

  class NoPinAuditLog < RaiseError
  end

  class PatronError < RaiseError
  end
  
  class CallPatronFail < PatronError
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
      super(500, 'Retrieve balance from wallet fail.', data)
    end
  end

  class AlreadyProcessed < RequestError
    def initialize(data=nil)
      super(400, 'The transaction has been already processed.', data)
    end
  end

  class DepositNotCompleted < RequestError
    def initialize(data=nil)
      super(400, 'The transaction has not been completed.', data)
    end
  end

  class DuplicateTrans < RequestError
    def initialize(data=nil)
      super(400, 'Ref_trans_id is duplicated.', data)
    end
  end

  class InvalidAmount < RequestError
    def initialize(data=nil)
      super(400, 'Amount is invalid.', data)
    end
  end

  class OutOfDailyLimit < RequestError
    def initialize(data=nil)
      super(400, 'Exceed the daily fund limit.', data)
    end
  end

  class AlreadyCancelled < RequestError
    def initialize(data=nil)
      super(400, 'The transaction has been already cancelled.', data)
    end
  end

  class InvalidDeposit < RequestError
    def initialize(data=nil)
      super(400, 'The transaction is invalid.', data)
    end
  end

  class AmountNotEnough < RequestError
    def initialize(data=nil)
      super(400, 'Amount is invalid.', data)
    end
  end
end
