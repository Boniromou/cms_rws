require "feature_spec_helper"
require "rails_helper"

describe MachinesController do
  def clean_dbs
    Token.delete_all
    PlayersLockType.delete_all
    Player.delete_all    
  end

  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[39] Validate machine token API' do
    before(:each) do
      clean_dbs
      bypass_rescue
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    after(:each) do
      clean_dbs
    end

    it '[39.1] Validate machine token success' do
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return(Requester::StationResponse.new({:error_code => 'OK', :error_msg => 'Request is carried out successfully.', :location_name => '0102', :zone_name => '01'}))
      get 'validate', {:machine_token => "20000|1|01|4|0102|2|abc1234|6e80a295eeff4554bf025098cca6eb37", :property_id => "20000"}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:location_name]).to eq '0102'
      expect(result[:zone_name]).to eq '01'
    end

    it '[39.2] Validate machine token fail' do
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return(Requester::StationResponse.new({:error_code => 'InvalidMachineToken', :error_msg => 'Validate terminal id failed.'}))
      get 'validate', {:machine_token => "20000|1|01|4|0102|2|abc1234|6e80a295eeff4554bf025098cca6eb37", :property_id => "20000"}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidMachineToken'
      expect(result[:error_msg]).to eq 'Validate terminal id failed.'
    end
  end
end
