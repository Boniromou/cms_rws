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
end
