class PlayersLockType < ActiveRecord::Base
  attr_accessible :player_id, :lock_type_id, :status
  belongs_to :player
  belongs_to :lock_type

  STATUS_ACTIVE = 'active'
  STATUS_INACTIVE = 'inactive'
  
  class << self
    def add_lock_to_player(player_id, lock_type_name)
      create_or_find_lock(player_id, lock_type_name, STATUS_ACTIVE)
    end
    
    def remove_lock_to_player(player_id, lock_type_name)
      create_or_find_lock(player_id, lock_type_name, STATUS_INACTIVE)
    end

    def create_or_find_lock(player_id, lock_type_name, status)
      lock_type = LockType.find_by_name(lock_type_name)
      raise 'lock type not found' unless lock_type
      @players_lock_type = PlayersLockType.where(:player_id => player_id, :lock_type_id => lock_type.id, :status => [STATUS_ACTIVE,STATUS_INACTIVE]).first_or_create
      @players_lock_type.status = status
      @players_lock_type.save
    end
  end
end
