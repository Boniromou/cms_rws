class Station < ActiveRecord::Base
  attr_accessible :name

  belongs_to :location

  scope :active, -> { where("status = ?", 'active')	}
  scope :inactive, -> { where("status = ?", 'inactive') }

  class << self
    def get_name_by_id( id )
      Station.find_by_id(id).name
    end
  end
end
