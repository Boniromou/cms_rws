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

module AddLocation
  class AddLocationError < CageError
  end

  class AlreadyExistedError < AddLocationError
  end

  class CantBlankError < AddLocationError
  end
end

module DisableLocation
  class DisableLocationError < CageError
  end

  class DisableFailError < DisableLocationError
  end

  class AlreadyDisabledError < DisableLocationError
  end
end

module EnableLocation
  class EnableLocationError < CageError
  end

  class AlreadyEnabledError < EnableLocationError
  end
end

module StationError
  class CreateStationError < CageError
  end

  class DuplicatedFieldError < CreateStationError
  end

  class ParamsError < CreateStationError
  end
  
  class EnableStationError < CageError
  end

  class AlreadyEnabledError < EnableStationError
  end
  
  class EnableFailError < EnableStationError
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
