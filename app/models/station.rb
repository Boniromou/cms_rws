class Station < ActiveRecord::Base
  attr_accessible :name, :location_id, :machine_id, :status
  validates_uniqueness_of :name, :scope => :location_id

  belongs_to :location

  scope :active, -> { where("status = ?", 'active')	}
  scope :inactive, -> { where("status = ?", 'inactive') }

  def change_status(target_status)
    raise StationError::AlreadyEnabledError, "already_disabled" if self.status == target_status
    raise StationError::EnableFailError, "location_invalid" if self.location_inactive?
  	self.status = target_status
    p "change status",self.status
    self.save
  end

  def location_inactive?
    return true if self.location.status == "inactive"
    false
  end

  class << self
    def get_name_by_id( id )
      Station.find_by_id(id).name
    end

    def create_by_params(params)
      verify_params(params)
      
      location_id = params[:location_id]
      name = params[:name].upcase
      begin
        Station.create!(:location_id => location_id, :name => name, :status => "active")
      rescue ActiveRecord::RecordInvalid => ex
        raise StationError::DuplicatedFieldError, "station.already_existed"
      end
    end
    def verify_params(params)
      location_id = params[:location_id]
      name = params[:name]
      raise StationError::ParamsError, "location.cant_blank" if location_id.nil? || location_id.blank?
      raise StationError::ParamsError, "station.cant_blank" if name.nil? || name.blank?
    end
  end
end
