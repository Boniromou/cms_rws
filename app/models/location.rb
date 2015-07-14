class Location < ActiveRecord::Base
  attr_accessible :name, :status

  has_many :stations, :dependent => :destroy

  
  scope :active, -> { where("status = ?", true)	}
  scope :inactive, -> { where("status = ?", false) }
 

  STATUS_ACTIVE = 'active'
  STATUS_INACTIVE = 'inactive'

  class << self
    def create_by_name(name)
      verify_location_name(name)

      name_upper = name.upcase
      
      location = new
      location.name = name_upper
      location.status = STATUS_ACTIVE
      
      begin
        location.save!
      rescue ActiveRecord::RecordInvalid => ex
        duplicated_filed = ex.record.errors.keys.first.to_s
        raise CreateLocation::DuplicatedFieldError, duplicated_filed
      end
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
      
      raise CreateLocation::ParamsError, "name_blank_error" if name.nil? || name.blank?

      raise CreateLocation::ParamsError, "name_exist" if duplicated_name
    end
  end



  def has_active_station?
    self.stations.active != nil
  end

  def disable!
  	self.status = STATUS_INACTIVE
    self.save
  end

  def enable!
  	self.status = STATUS_ACTIVE
    self.save
  end
end
