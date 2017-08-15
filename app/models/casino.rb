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

    def get_find_first_casino_id_by_licensee_id(licensee_id)
      casino = Casino.find_by_licensee_id(licensee_id)
      return nil unless casino
      casino.id
    end
  end
end
