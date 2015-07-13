class StationPolicy < ApplicationPolicy
  
  def list?
    return true
  end

  def create?
    return true
  end
  
  def enable?
  return true
  end

end
