require 'cronjob_spec_helper'

describe Token do
  def clean_dbs
    Token.delete_all
    PlayersLockType.delete_all
    Player.delete_all
  end

  describe '[40] Regular delete expired token' do
    before(:each) do
      clean_dbs
      @player1 = Player.create!(:first_name => "exist1", :last_name => "exist2", :member_id => 123456, :currency_id => 2, :status => "active", :licensee_id => 20000)
      @player2 = Player.create!(:first_name => "exist2", :last_name => "exist3", :member_id => 123457, :currency_id => 2, :status => "active", :card_id => 123, :licensee_id => 20000)
      @token1 = Token.generate(@player1.id)
      @token2 = Token.generate(@player1.id)
      @token3 = Token.generate(@player2.id)
      @token4 = Token.generate(@player2.id)
    end

    it '[40.1] delete expired token' do
      @token1.expired_at = Time.now - 100
      @token1.save!
      @token3.expired_at = Time.now - 100
      @token3.save!
      expect(Token.find(:all).length).to eq 4
      Cronjob::CleanTokenHelper.new.run
      expect(Token.find(:all).length).to eq 2
    end
  end
end
