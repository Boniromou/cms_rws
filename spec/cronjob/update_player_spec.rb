require 'cronjob_spec_helper'

describe Player do
  def clean_dbs
    Token.delete_all
    PlayersLockType.delete_all
    Player.delete_all
  end

  describe '[51] Regular Update player info, Expire token when info changed' do
    before(:each) do
      clean_dbs
      @player1 = Player.create!(:first_name => "exist1", :last_name => "exist2", :member_id => '123456', :currency_id => 1, :status => "active", :card_id => '456', :property_id => 20000)
      @player2 = Player.create!(:first_name => "exist2", :last_name => "exist3", :member_id => '123457', :currency_id => 1, :status => "active", :card_id => '123', :property_id => 20000)
      @token1 = Token.generate(@player1.id)
      @token2 = Token.generate(@player1.id)
      @token3 = Token.generate(@player2.id)
      @token4 = Token.generate(@player2.id)
      @requester_config_file = "#{Rails.root}/config/requester_config.yml"
      allow(Property).to receive(:all).and_return(Property.where(:id => 20000))
    end

    it '[51.1] get player info success without player info change' do
      @player_info1 = {:card_id => @player1.card_id, :member_id => @player1.member_id, :blacklist => @player1.has_lock_type?('blacklist'), :pin_status => 'created' }
      @player_info2 = {:card_id => @player2.card_id, :member_id => @player2.member_id, :blacklist => @player2.has_lock_type?('blacklist'), :pin_status => 'created' }
      allow_any_instance_of(Requester::Patron).to receive(:get_player_infos).and_return([@player_info1,@player_info2])
      Cronjob::UpdatePlayerHelper.new('test', @requester_config_file).run
      
      p = Player.find(@player1.id)
      expect(p.member_id).to eq @player1.member_id
      expect(p.card_id).to eq @player1.card_id
      expect(p.status).to eq @player1.status
      
      p = Player.find(@player2.id)
      expect(p.member_id).to eq @player2.member_id
      expect(p.card_id).to eq @player2.card_id
      expect(p.status).to eq @player2.status
    end

    it '[51.2] get player info success with card ID change' do
      @player_info1 = {:card_id => '123456', :member_id => @player1.member_id, :blacklist => @player1.has_lock_type?('blacklist'), :pin_status => 'created' }
      @player_info2 = {:card_id => @player2.card_id, :member_id => @player2.member_id, :blacklist => @player2.has_lock_type?('blacklist'), :pin_status => 'created' }
      allow_any_instance_of(Requester::Patron).to receive(:get_player_infos).and_return([@player_info1,@player_info2])
      Cronjob::UpdatePlayerHelper.new('test', @requester_config_file).run
      
      p = Player.find(@player1.id)
      expect(p.member_id).to eq @player1.member_id
      expect(p.card_id).to eq '123456'
      expect(p.status).to eq @player1.status
      
      p = Player.find(@player2.id)
      expect(p.member_id).to eq @player2.member_id
      expect(p.card_id).to eq @player2.card_id
      expect(p.status).to eq @player2.status
    end

    it '[51.3] get player info success with blacklist change' do
      @player_info1 = {:card_id => @player1.card_id, :member_id => @player1.member_id, :blacklist => !@player1.has_lock_type?('blacklist'), :pin_status => 'created' }
      @player_info2 = {:card_id => @player2.card_id, :member_id => @player2.member_id, :blacklist => !@player2.has_lock_type?('blacklist'), :pin_status => 'created' }
      allow_any_instance_of(Requester::Patron).to receive(:get_player_infos).and_return([@player_info1,@player_info2])
      Cronjob::UpdatePlayerHelper.new('test', @requester_config_file).run
      
      p = Player.find(@player1.id)
      expect(p.member_id).to eq @player1.member_id
      expect(p.card_id).to eq @player1.card_id
      expect(p.status).to eq 'locked'
      expect(p.has_lock_type?('blacklist')).to eq true
      
      p = Player.find(@player2.id)
      expect(p.member_id).to eq @player2.member_id
      expect(p.card_id).to eq @player2.card_id
      expect(p.status).to eq 'locked'
      expect(p.has_lock_type?('blacklist')).to eq true
    end

    it '[51.4] get player info success with PIN change' do
      @player_info1 = {:card_id => @player1.card_id, :member_id => @player1.member_id, :blacklist => @player1.has_lock_type?('blacklist'), :pin_status => 'reset' }
      @player_info2 = {:card_id => @player2.card_id, :member_id => @player2.member_id, :blacklist => @player2.has_lock_type?('blacklist'), :pin_status => 'reset' }
      allow_any_instance_of(Requester::Patron).to receive(:get_player_infos).and_return([@player_info1,@player_info2])
      Cronjob::UpdatePlayerHelper.new('test', @requester_config_file).run
      
      p = Player.find(@player1.id)
      expect(p.member_id).to eq @player1.member_id
      expect(p.card_id).to eq @player1.card_id
      expect(p.status).to eq @player1.status
      
      p = Player.find(@player2.id)
      expect(p.member_id).to eq @player2.member_id
      expect(p.card_id).to eq @player2.card_id
      expect(p.status).to eq @player2.status


      @token1.reload
      @token2.reload
      @token3.reload
      @token4.reload
      expect(@token1.alive?).to eq false
      expect(@token2.alive?).to eq false
      expect(@token3.alive?).to eq false
      expect(@token4.alive?).to eq false
    end
  end
end
