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
    self.save
  end

  def register(machine_id)
    raise StationError::StationAlreadyRegisterError, "already_register" unless self.machine_id.nil?
    raise StationError::MachineAlreadyRegisterError, "machine_already_register" if Station.machine_registered?(machine_id)
    self.machine_id = machine_id
    self.save
  end

  def unregister
    raise StationError::StationAlreadyUnregisterError, "already_unregister" if self.machine_id.nil?
    self.machine_id = nil
    self.save
  end

  def location_inactive?
    return true if self.location.status == "inactive"
    false
  end

  def full_name
    location_name = self.location.name
    location_name + "-" + name
  end

  class << self
    def get_name_by_id( id )
      Station.find_by_id(id).name
    end

    def get_full_name_by_machine_id(machine_id)
      station = Station.find_by_machine_id(machine_id)
      return "no station" if station.nil?
      station.full_name
    end

    def create_by_params(params)
      verify_params(params)
      
      location_id = params[:location_id]
      name = params[:name].upcase
      begin
        Station.create!(:location_id => location_id, :name => name, :status => "active")
      rescue ActiveRecord::RecordInvalid => ex
        raise StationError::DuplicatedFieldError, "station.already_existed" if ex.message == "Validation failed: Name has already been taken"
        raise ex
      end
    end

    def verify_params(params)
      location_id = params[:location_id]
      name = params[:name]
      raise StationError::ParamsError, "location.cant_blank" if location_id.nil? || location_id.blank?
      raise StationError::ParamsError, "station.cant_blank" if name.nil? || name.blank?
    end

    def machine_registered?(machine_id)
      result = self.find_by_machine_id(machine_id)
      return !result.nil?
    end
  end
end
