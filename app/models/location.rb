class Location < ActiveRecord::Base
  attr_accessible :name, :status
  validates_uniqueness_of :name

  has_many :stations, :dependent => :destroy

  
  scope :active, -> { where("status = ?", true)	}
  scope :inactive, -> { where("status = ?", false) }
 
  class << self
    def create_by_name(name)
      verify_location_name(name)

      begin
        Location.create!(:name => name.upcase, :status => "active")
      rescue ActiveRecord::RecordInvalid => ex
        raise LocationError::AlreadyExistedError, "already_existed" if ex.message == "Validation failed: Name has already been taken"
        raise ex
      end
    
    end
    
    def get_name_by_id( id )
      Location.find_by_id(id).name
    end

    def verify_location_name(name)   
      raise LocationError::CantBlankError, "cant_blank" if name.nil? || name.blank?
    end
  end



  def has_active_station?
    self.stations.active != []
  end

  def change_status(target_status)
    raise LocationError::DisableFailError, "disable_fail" if has_active_station? && target_status == "inactive"
    raise LocationError::DuplicatedChangeStatusError if self.status == target_status
    self.status = target_status
    self.save
  end

end
