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
