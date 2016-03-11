class Licensee < ActiveRecord::Base
  attr_accessible :name
  has_many :casinos
end
