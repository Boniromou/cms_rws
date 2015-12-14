class ApplicationPolicy
  include Rigi::PunditHelper::Policy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end
  
  def have_active_location?
    @user.have_active_location
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def has_permission?(target, action)
    cache_key = "#{APP_NAME}:permissions:#{user.uid}"
    permissions = Rails.cache.fetch cache_key
    actions = permissions[:permissions][:permissions][target.to_sym] if permissions
    return true if actions && (actions.include? action)
    return false
  end

  def is_admin?
    cache_key = "#{user.uid}"
    status = Rails.cache.fetch cache_key
    return false unless status
    status[:admin]
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(:property_id => user.property_id)
    end
  end
end

