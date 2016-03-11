class Casino < ActiveRecord::Base
  attr_accessible :name, :licensee_id
  has_many :properties
  belongs_to :licensee
end
