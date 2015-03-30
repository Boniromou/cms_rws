class User < ActiveRecord::Base
  devise :registerable

  attr_accessible :employee_id, :uid
end
