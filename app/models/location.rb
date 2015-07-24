class Location < ActiveRecord::Base
  attr_accessible :name, :status

  has_many :stations, :dependent => :destroy

  
  scope :active, -> { where("status = ?", true)	}
  scope :inactive, -> { where("status = ?", false) }
 
  class << self
    def create_by_name(name)
      verify_location_name(name)

      name_upper = name.upcase
      
      location = new
      location.name = name_upper
      location.status = STATUS_ACTIVE
      
     
        location.save!
     
    
    end


    def verify_location_name(name)
      name_upper = name.upcase

      duplicated_name = false

      self.all.each do | location |
        if location.name == name_upper
          duplicated_name = true
          break
        end
      end
      
      raise AddLocation::CantBlankError, "cant_blank" if name.nil? || name.blank?

      raise AddLocation::AlreadyExistedError, "already_existed" if duplicated_name
    end
  end



  def has_active_station?
    self.stations.active != []
  end

  def disable!
    raise DisableLocation::DisableFailError, "disable_fail" if has_active_station?
    raise DisableLocation::AlreadyDisabledError, "already_disabled" if self.status == STATUS_INACTIVE
  	self.status = STATUS_INACTIVE
    self.save

  end

  def enable!
    raise EnableLocation::AlreadyEnabledError, "already_disabled" if self.status == STATUS_ACTIVE
  	self.status = STATUS_ACTIVE
    self.save
  end
end
