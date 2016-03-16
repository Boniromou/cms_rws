class Casino < ActiveRecord::Base
  attr_accessible :name, :licensee_id
  has_many :properties
  belongs_to :licensee
  
  class << self
    def get_licensee_id_by_casino_id(casino_id)
      casino = Casino.find_by_id(casino_id)
      return nil unless casino
      casino.licensee.id
    end
  end
end
