class Station < ActiveRecord::Base
  attr_accessible :name, :location_id, :status
  class << self
    def get_name_by_id( id )
      Station.find_by_id(id).name
    end

    def create_by_params(params)
      verify_params(params)
      
      location_id = params[:location]
      name = params[:name]
      begin
        Station.create!(:location_id => location_id, :name => name, :status => "active")
      rescue ActiveRecord::RecordInvalid => ex
        duplicated_filed = ex.record.errors.keys.first.to_s
        raise CreatePlayer::DuplicatedFieldError, duplicated_filed
      end
    end
    def verify_params(params)
      location_id = params[:location]
      name = params[:name]

      raise CreateStation::ParamsError, "card_id_length_error" if location_id.nil? || location_id.blank?
      raise CreateStation::ParamsError, "member_id_length_error" if name.nil? || name.blank?
    end
  end
end
