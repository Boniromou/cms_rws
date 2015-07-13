class Location < ActiveRecord::Base
  attr_accessible :name, :status
  
  scope :active, -> { where("status = ?", true)	}
  scope :inactive, -> { where("status = ?", false) }
  scope :search, lambda { |keyword| where("description = ?", "%#{keyword}%")}

  class << self
    def create_by_params(params)
      verify_location_params(params)

      name = params[:name].upcase
      
      location = new
      location.name = name
      location.status = ACTIVE
      begin
        location.save!
      rescue ActiveRecord::RecordInvalid => ex
        duplicated_filed = ex.record.errors.keys.first.to_s
        raise CreateLocation::DuplicatedFieldError, duplicated_filed
      end
    end


    def verify_location_params(params)
      name = params[:name].upcase

      duplicated_name = false

      self.all.each do | location |
        if location.name == name
          duplicated_name = true
          break
        end
      end
      
      raise CreateLocation::ParamsError, "name_length_error" if name.nil? || name.blank?

      raise CreateLocation::ParamsError, "duplicated_name_error" if duplicated_name
    end
  end




  def disable
  	puts "sdfdsfsdfssdf"
  	puts "sdfdsfsdfssdf"
  	puts "sdfdsfsdfssdf"
  	puts "sdfdsfsdfssdf"
  	puts "sdfdsfsdfssdf"
  	puts "sdfdsfsdfssdf"
  	self.status = false
  	self.save!
  end

  def enable
  	self.status = true
  	self.save!
  end
end
