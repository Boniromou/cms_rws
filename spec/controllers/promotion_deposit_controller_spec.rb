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

  describe '[10] Promotion Deposit' do
    before(:each) do
    clean_dbs
    create_shift_data
    @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
    @promotion_code = "PRO000021"
    @executed_by = "queenie"
    @ref_trans_id = nil
    @sourse_type = "promotion_deposit" 

    wallet_response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => 100.00, :redit_balance => 0.0, :credit_expired_at => nil})
    allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(wallet_response) 
    deposit_response = Requester::WalletTransactionResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.', :trans_date => Time.now.strftime("%Y-%m-%d %H:%M:%S"), :before_balance => 100, :after_balance => 300})
    allow_any_instance_of(Requester::Wallet).to receive(:deposit).and_return(deposit_response)
    end

    after(:each) do
      clean_dbs
    end

    it '[10.1.1] OK - mass_top_up' do
      ib = {
            :login_name => @player.member_id, 
            :amt => "200", 
            :ref_trans_id => @ref_trans_id, 
            :sourse_type => @promotion_deposit, 
            :casino_id => 20000, 
            :promotion_code => @promotion_code, 
            :executed_by => @executed_by, 
            :promotion_type => "mass_top_up"
            }
      post 'internal_deposit', ib
      result = JSON.parse(response.body).symbolize_keys
      player_transaction = PlayerTransaction.first
      player_transaction_data  = YAML.load(player_transaction.data).symbolize_keys
      p player_transaction_data
      expect(player_transaction.player_id).to eq @player.id
      expect(player_transaction.amount).to eq 20000
      expect(player_transaction.transaction_type.name).to eq 'deposit'
      expect(player_transaction.promotion_code).to eq @promotion_code
      expect(player_transaction_data[:promotion_detail][:promotion_type]).to eq "Mass Top Up"
      expect(player_transaction_data[:promotion_detail][:award_condition]).to eq "Top Up Amount = 200.0"
      expect(player_transaction_data[:promotion_detail][:occurrences]).to eq 1        
      expect(player_transaction_data[:executed_by]).to eq 'queenie'
      expect(player_transaction.status).to eq 'completed'
      expect(player_transaction.casino_id).to eq 20000
    
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
    end

    it '[10.1.2] OK - daily_top_off' do
      ib = {
            :login_name => @player.member_id,
            :amt => "200",
            :ref_trans_id => @ref_trans_id,
            :sourse_type => @promotion_deposit,
            :casino_id => 20000,
            :promotion_code => @promotion_code,
            :promotion_type => "daily_top_off",
            :top_off_amt => 200
            }
      post 'internal_deposit', ib
      result = JSON.parse(response.body).symbolize_keys
      player_transaction = PlayerTransaction.first
      player_transaction_data  = YAML.load(player_transaction.data).symbolize_keys
      p player_transaction_data
      expect(player_transaction.player_id).to eq @player.id
      expect(player_transaction.amount).to eq 20000
      expect(player_transaction.transaction_type.name).to eq 'deposit'
      expect(player_transaction.promotion_code).to eq @promotion_code
      expect(player_transaction_data[:promotion_detail][:promotion_type]).to eq "Daily Top Off"
      expect(player_transaction_data[:promotion_detail][:award_condition]).to eq "if Account Balance < 200.0, top off to 200.0"
      expect(player_transaction_data[:promotion_detail][:occurrences]).to eq 0.0
      expect(player_transaction.status).to eq 'completed'
      expect(player_transaction.casino_id).to eq 20000

      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
    end

    it '[10.1.3] OK - daily_rounds_award' do
      ib = {
            :login_name => @player.member_id,
            :amt => "300",
            :ref_trans_id => @ref_trans_id,
            :sourse_type => @promotion_deposit,
            :casino_id => 20000,
            :promotion_code => @promotion_code,
            :promotion_type => "daily_rounds_award",
            :threshold => 20,
            :max => 2,
            :each_award => 150, 
            :count => 44
            }
      post 'internal_deposit', ib
      result = JSON.parse(response.body).symbolize_keys
      player_transaction = PlayerTransaction.first
      player_transaction_data  = YAML.load(player_transaction.data).symbolize_keys
      p player_transaction_data
      expect(player_transaction.player_id).to eq @player.id
      expect(player_transaction.amount).to eq 30000
      expect(player_transaction.transaction_type.name).to eq 'deposit'
      expect(player_transaction.promotion_code).to eq @promotion_code
      expect(player_transaction_data[:promotion_detail][:promotion_type]).to eq "Daily Rounds Award"
      expect(player_transaction_data[:promotion_detail][:award_condition]).to eq "Threshold = 20 rounds, Max = 2, Each Award = 150.0"
      expect(player_transaction_data[:promotion_detail][:occurrences]).to eq 44
      expect(player_transaction.status).to eq 'completed'
      expect(player_transaction.casino_id).to eq 20000

      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
    end

    it '[10.1.4] OK - daily_login_award' do
      ib = {
            :login_name => @player.member_id,
            :amt => "300",
            :ref_trans_id => @ref_trans_id,
            :sourse_type => @promotion_deposit,
            :casino_id => 20000,
            :promotion_code => @promotion_code,
            :promotion_type => "daily_login_award",
            :threshold => 1,
            :max => 2,
            :each_award => 150,
            :count => 4
            }
      post 'internal_deposit', ib
      result = JSON.parse(response.body).symbolize_keys
      player_transaction = PlayerTransaction.first
      player_transaction_data  = YAML.load(player_transaction.data).symbolize_keys
      p player_transaction_data
      expect(player_transaction.player_id).to eq @player.id
      expect(player_transaction.amount).to eq 30000
      expect(player_transaction.transaction_type.name).to eq 'deposit'
      expect(player_transaction.promotion_code).to eq @promotion_code
      expect(player_transaction_data[:promotion_detail][:promotion_type]).to eq "Daily Login Award"
      expect(player_transaction_data[:promotion_detail][:award_condition]).to eq "Threshold = 1 login, Max = 2, Each Award = 150.0"
      expect(player_transaction_data[:promotion_detail][:occurrences]).to eq 4
      expect(player_transaction.status).to eq 'completed'
      expect(player_transaction.casino_id).to eq 20000

      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
    end

    it '[10.1.5] OK - initial_amount' do
      ib = {
            :login_name => @player.member_id,
            :amt => "200",
            :ref_trans_id => @ref_trans_id,
            :sourse_type => @promotion_deposit,
            :casino_id => 20000,
            :promotion_code => @promotion_code,
            :promotion_type => "initial_amount"
            }
      post 'internal_deposit', ib
      result = JSON.parse(response.body).symbolize_keys
      player_transaction = PlayerTransaction.first
      player_transaction_data  = YAML.load(player_transaction.data).symbolize_keys
      p player_transaction_data
      expect(player_transaction.player_id).to eq @player.id
      expect(player_transaction.amount).to eq 20000
      expect(player_transaction.transaction_type.name).to eq 'deposit'
      expect(player_transaction.promotion_code).to eq @promotion_code
      expect(player_transaction_data[:promotion_detail][:promotion_type]).to eq "Initial Amount"
      expect(player_transaction_data[:promotion_detail][:award_condition]).to eq "First Login"
      expect(player_transaction_data[:promotion_detail][:occurrences]).to eq 1
      expect(player_transaction.status).to eq 'completed'
      expect(player_transaction.casino_id).to eq 20000

      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
    end

    it '[10.2] duplicate promotion_code' do
      ib = {
            :login_name => @player.member_id,
            :amt => "200",
            :ref_trans_id => @ref_trans_id,
            :sourse_type => @promotion_deposit,
            :casino_id => 20000,
            :promotion_code => @promotion_code,
            :executed_by => @executed_by,
            :promotion_type => "mass_top_up"
            }
      post 'internal_deposit', ib
      wallet_response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => 300.00, :redit_balance => 0.0, :credit_expired_at => nil})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(wallet_response) 
      deposit_response = Requester::WalletTransactionResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.', :trans_date => Time.now.strftime("%Y-%m-%d %H:%M:%S"), :before_balance => 300, :after_balance => 400})
      allow_any_instance_of(Requester::Wallet).to receive(:deposit).and_return(deposit_response)

      post 'internal_deposit', ib
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'AlreadyProcessed'

    end

    it '[10.3] InvalidLoginName' do
      ib = {
            :login_name => '1234567822',
            :amt => "200",
            :ref_trans_id => @ref_trans_id,
            :sourse_type => @promotion_deposit,
            :casino_id => 20000,
            :promotion_code => @promotion_code,
            :executed_by => @executed_by,
            :promotion_type => "mass_top_up"
            }
      post 'internal_deposit', ib
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidLoginName'       
    end    
  end
end
