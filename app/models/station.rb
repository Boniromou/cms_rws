class Station < ActiveRecord::Base
  attr_accessible :name, :location_id, :status
  validates_uniqueness_of :name, :scope => :location_id
  class << self
    def get_name_by_id( id )
      Station.find_by_id(id).name
    end

    def create_by_params(params)
      verify_params(params)
      
      location_id = params[:location_id]
      name = params[:name]
      begin
        Station.create!(:location_id => location_id, :name => name, :status => "active")
      rescue ActiveRecord::RecordInvalid => ex
        raise CreateStation::DuplicatedFieldError, "station.already_existed"
      end
    end
    def verify_params(params)
      location_id = params[:location_id]
      name = params[:name]
      raise CreateStation::ParamsError, "location.cant_blank" if location_id.nil? || location_id.blank?
      raise CreateStation::ParamsError, "station.cant_blank" if name.nil? || name.blank?
    end
  end
end
