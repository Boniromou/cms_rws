require "feature_spec_helper"
require "rails_helper"

describe KioskController do
  def clean_dbs
    Token.delete_all
    PlayersLockType.delete_all
    PlayerTransaction.delete_all
    KioskTransaction.delete_all
    Player.delete_all
    Shift.delete_all
    AccountingDate.delete_all
  end

  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[76] Login Kiosk API' do
    before(:each) do
      clean_dbs
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it '[76.1] Card ID is exist and generate token' do
      mock_token = "afe1f247-5eaa-4c2c-91c7-33a5fb637713"
      wallet_response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => 100.00, :credit_balance => 99.99, :credit_expired_at => @credit_expird_at})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(wallet_response)
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return(Requester::ValidatePinResponse.new({:error_code => 'OK'}))
      allow(SecureRandom).to receive(:uuid).and_return(mock_token)
      post 'kiosk_login', {:card_id => "1234567890", :kiosk_id => "1234567891", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:session_token]).to eq mock_token
      expect(result[:login_name]).to eq @player.member_id
      expect(result[:currency]).to eq Currency.find(@player.currency_id).name
      expect(result[:balance]).to eq 100.0
    end

    it '[76.2] Card ID is not exist' do
      post 'kiosk_login', {:card_id => "1234567891", :kiosk_id => "1234567891", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidCardId'
    end

    it '[76.3] Player is locked' do
      @player.lock_account!
      get 'kiosk_login', {:card_id => "1234567890", :kiosk_id => "1234567890", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'PlayerLocked'
    end

    it '[76.4] Validate PIN fail' do
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_raise(Remote::PinError)
      get 'kiosk_login', {:card_id => "1234567890", :kiosk_id => "1234567890", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidPin'
    end

    it '[76.5] Retrieve Balance fail' do
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return(Requester::ValidatePinResponse.new({:error_code => 'OK'}))
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(Requester::NoBalanceResponse.new)
      get 'kiosk_login', {:card_id => "1234567890", :kiosk_id => "1234567890", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'RetrieveBalanceFail'
    end
  end

  describe '[77] Validate Deposit API' do
    before(:each) do
      clean_dbs
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      @token = Token.generate(@player.id, 20000)
      @source_type = 'everi_kiosk'
      @kiosk_id = "1234567891"
      @ref_trans_id = 'EK00000001'
      create_shift_data
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
      wallet_response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => 100.00, :credit_balance => 99.99, :credit_expired_at => @credit_expird_at})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(wallet_response)
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it '[77.1] Success' do
      post 'validate_deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      kiosk_transaction = KioskTransaction.first
      expect(kiosk_transaction.player_id).to eq @player.id
      expect(kiosk_transaction.amount).to eq 10000
      expect(kiosk_transaction.transaction_type.name).to eq 'deposit'
      expect(kiosk_transaction.ref_trans_id).to eq 'EK00000001'
      expect(kiosk_transaction.source_type).to eq @source_type
      expect(kiosk_transaction.kiosk_name).to eq @kiosk_id
      expect(kiosk_transaction.status).to eq 'validated'
      expect(kiosk_transaction.casino_id).to eq 20000

      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:amt].to_f).to eq 100
      expect(result[:balance].to_f).to eq 200.00
      expect(result[:trans_date]).to eq kiosk_transaction.trans_date.localtime.strftime("%Y-%m-%d %H:%M:%S")
    end
    
    it '[77.2] AlreadyProcessed' do
      kiosk_transaction = KioskTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :transaction_type_id => 1, :ref_trans_id => @ref_trans_id, :amount => 10000, :status => 'validated', :trans_date => Time.now, :casino_id => 20000, :kiosk_name => @kiosk_id, :source_type => @source_type)
      post 'validate_deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'AlreadyProcessed'
      expect(result[:error_msg]).to eq 'The transaction has been already processed.'
    end
    
    it '[77.3] DuplicateTrans' do
      kiosk_transaction = KioskTransaction.create(:shift_id => Shift.last.id, :player_id => @player.id, :transaction_type_id => 1, :ref_trans_id => @ref_trans_id, :amount => 200.00, :status => 'validated', :trans_date => Time.now, :casino_id => 20000, :kiosk_name => @kiosk_id, :source_type => @source_type)
      post 'validate_deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'DuplicateTrans'
      expect(result[:error_msg]).to eq 'Ref_trans_id is duplicated.'
    end
    
    it '[77.4] InvalidAmount' do
      post 'validate_deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => -100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'InvalidAmount'
      expect(result[:error_msg]).to eq 'Amount is invalid.'
    end
    
    it '[77.5] InvalidLoginName' do
      post 'validate_deposit', {:login_name => '123', :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'InvalidLoginName'
      expect(result[:error_msg]).to eq 'Login name is invalid.'
    end
    
    it '[77.6] OutOfDailyLimit' do
      post 'validate_deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 9999999, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'OutOfDailyLimit'
      expect(result[:error_msg]).to eq 'Exceed the daily fund limit.'
    end
    
    it '[77.7] RetrieveBalanceFail' do
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(Requester::NoBalanceResponse.new)
      post 'validate_deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'RetrieveBalanceFail'
      expect(result[:error_msg]).to eq 'Retrieve balance from wallet fail.'
    end
    
    it '[77.8] InvalidSessionToken' do
      post 'validate_deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => 'abc', :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'InvalidSessionToken'
      expect(result[:error_msg]).to eq 'Session token is invalid.'
    end
  end
  
  describe '[78] Deposit API' do
    before(:each) do
      clean_dbs
      create_shift_data
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      @token = Token.generate(@player.id, 20000)
      @source_type = 'everi_kiosk'
      @kiosk_id = "1234567891"
      @ref_trans_id = 'EK00000001'
      @kiosk_transaction = KioskTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :transaction_type_id => 1, :ref_trans_id => @ref_trans_id, :amount => 10000, :status => 'validated', :trans_date => Time.now, :casino_id => 20000, :kiosk_name => @kiosk_id, :source_type => @source_type)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
      wallet_response = Requester::WalletTransactionResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.', :trans_date => Time.now.strftime("%Y-%m-%d %H:%M:%S"), :before_balance => 100, :after_balance => 200})
      allow_any_instance_of(Requester::Wallet).to receive(:deposit).and_return(wallet_response)
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it '[78.1] Success' do
      post 'deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      kiosk_transaction = KioskTransaction.first
      expect(kiosk_transaction.player_id).to eq @player.id
      expect(kiosk_transaction.amount).to eq 10000
      expect(kiosk_transaction.transaction_type.name).to eq 'deposit'
      expect(kiosk_transaction.ref_trans_id).to eq @ref_trans_id
      expect(kiosk_transaction.source_type).to eq @source_type
      expect(kiosk_transaction.kiosk_name).to eq @kiosk_id
      expect(kiosk_transaction.status).to eq 'completed'
      expect(kiosk_transaction.casino_id).to eq 20000

      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
    end

    it '[78.2] InvalidDeposit' do
      @kiosk_transaction.delete
      post 'deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys

      expect(result[:error_code]).to eq 'InvalidDeposit'
      expect(result[:error_msg]).to eq 'The transaction is invalid.'
    end

    it '[78.3] AlreadyCancelled' do
      @kiosk_transaction.status = 'cancelled'
      @kiosk_transaction.save!
      post 'deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys

      expect(result[:error_code]).to eq 'AlreadyCancelled'
      expect(result[:error_msg]).to eq 'The transaction has been already cancelled.'
    end

    it '[78.4] InvalidSessionToken' do
      post 'deposit', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :kiosk_id => @kiosk_id, :session_token => 'abc', :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys

      expect(result[:error_code]).to eq 'InvalidSessionToken'
      expect(result[:error_msg]).to eq 'Session token is invalid.'
    end
  end

  describe '[79] Withdraw API' do
    before(:each) do
      clean_dbs
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      @token = Token.generate(@player.id, 20000)
      @source_type = 'everi_kiosk'
      @kiosk_id = "1234567891"
      @ref_trans_id = 'EK00000001'
      create_shift_data
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
      wallet_response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => 100.00, :credit_balance => 99.99, :credit_expired_at => @credit_expird_at})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(wallet_response)
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it '[79.1] Success' do
      wallet_response = Requester::WalletTransactionResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.', :trans_date => Time.now.strftime("%Y-%m-%d %H:%M:%S"), :before_balance => 200, :after_balance => 100})
      allow_any_instance_of(Requester::Wallet).to receive(:withdraw).and_return(wallet_response)
      post 'withdraw', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      kiosk_transaction = KioskTransaction.first
      expect(kiosk_transaction.player_id).to eq @player.id
      expect(kiosk_transaction.amount).to eq 10000
      expect(kiosk_transaction.transaction_type.name).to eq 'withdraw'
      expect(kiosk_transaction.ref_trans_id).to eq 'EK00000001'
      expect(kiosk_transaction.source_type).to eq @source_type
      expect(kiosk_transaction.kiosk_name).to eq @kiosk_id
      expect(kiosk_transaction.status).to eq 'completed'
      expect(kiosk_transaction.casino_id).to eq 20000

      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:amt].to_f).to eq 100
      expect(result[:balance].to_f).to eq 100.00
      expect(result[:trans_date]).to eq kiosk_transaction.trans_date.localtime.strftime("%Y-%m-%d %H:%M:%S")
    end
    
    it '[79.2] AlreadyProcessed' do
      kiosk_transaction = KioskTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :transaction_type_id => 2, :ref_trans_id => @ref_trans_id, :amount => 10000, :status => 'completed', :trans_date => Time.now, :casino_id => 20000, :kiosk_name => @kiosk_id, :source_type => @source_type)
      post 'withdraw', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'AlreadyProcessed'
      expect(result[:error_msg]).to eq 'The transaction has been already processed.'
    end
    
    it '[79.3] DuplicateTrans' do
      kiosk_transaction = KioskTransaction.create(:shift_id => Shift.last.id, :player_id => @player.id, :transaction_type_id => 2, :ref_trans_id => @ref_trans_id, :amount => 200.00, :status => 'completed', :trans_date => Time.now, :casino_id => 20000, :kiosk_name => @kiosk_id, :source_type => @source_type)
      post 'withdraw', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'DuplicateTrans'
      expect(result[:error_msg]).to eq 'Ref_trans_id is duplicated.'
    end
    
    it '[79.5] InvalidAmount' do
      post 'withdraw', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => -100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'InvalidAmount'
      expect(result[:error_msg]).to eq 'Amount is invalid.'
    end
    
    it '[79.6] InvalidLoginName' do
      post 'withdraw', {:login_name => '123', :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'InvalidLoginName'
      expect(result[:error_msg]).to eq 'Login name is invalid.'
    end
    
    it '[79.7] OutOfDailyLimit' do
      post 'withdraw', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 9999999, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'OutOfDailyLimit'
      expect(result[:error_msg]).to eq 'Exceed the daily fund limit.'
    end
    
    it '[79.8] RetrieveBalanceFail' do
      allow_any_instance_of(Requester::Wallet).to receive(:withdraw).and_raise('fail')
      post 'withdraw', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => @token.session_token, :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'RetrieveBalanceFail'
      expect(result[:error_msg]).to eq 'Retrieve balance from wallet fail.'
    end
    
    it '[79.9] InvalidSessionToken' do
      post 'withdraw', {:login_name => @player.member_id, :ref_trans_id => @ref_trans_id, :amt => 100.00, :kiosk_id => @kiosk_id, :session_token => 'abc', :source_type => @source_type, :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      
      expect(result[:error_code]).to eq 'InvalidSessionToken'
      expect(result[:error_msg]).to eq 'Session token is invalid.'
    end
  end
end
