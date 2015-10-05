class PlayersLockType < ActiveRecord::Base
  attr_accessible :player_id, :lock_type_id, :status
  belongs_to :player
  belongs_to :lock_type

  STATUS_ACTIVE = 'active'
  STATUS_INACTIVE = 'inactive'
  
  class << self
    def add_lock_to_player(player_id, lock_type_name)
      lock_type = LockType.find_by_name(lock_type_name)
      raise 'lock type not found' unless lock_type
      @players_lock_type = PlayersLockType.where(:player_id => player_id, :lock_type_id => lock_type.id).first_or_create
      @players_lock_type.status = STATUS_ACTIVE
      @players_lock_type.save
    end
    
    def remove_lock_to_player(player_id, lock_type_name)
      lock_type = LockType.find_by_name(lock_type_name)
      raise 'lock type not found' unless lock_type
      @players_lock_type = PlayersLockType.where(:player_id => player_id, :lock_type_id => lock_type.id).first_or_create
      @players_lock_type.status = STATUS_INACTIVE
      @players_lock_type.save
    end
  end
end
