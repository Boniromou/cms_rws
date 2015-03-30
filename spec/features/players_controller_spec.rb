require "feature_spec_helper"

describe PlayersController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    User.delete_all
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
  end

  after(:all) do
    User.lelete_all
    Warden.test_reset!
  end

  describe '[3] Create player' do
    before(:each) do
      Player.delete_all
    end

    after(:each) do
      Player.delete_all
    end

    it '[3.1] show' do
    end
  end
end
