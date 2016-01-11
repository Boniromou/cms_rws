require 'spec_helper'

include Hood

describe Player, "lock" do
  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'s',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>20010,
                          :created_at=>Time.now.utc,:updated_at=>Time.now.utc,:lock_state=>'unlocked')
  end

  it "lock sucess" do
    Player.lock(1000,'abc') do |player|
      expect(player[:id]).to eq 123
      expect(player[:property_id]).to eq 1000
      expect(player[:login_name]).to eq('abc')
      expect(player[:lock_state]).to eq('locked')
    end
    expect(Player[123][:lock_state]).to eq('unlocked')
  end

  it "lock failed" do
    player = Player[123]
    player[:lock_state] = 'locked'
    player.save
    a = 0
    expect{
      Player.lock(1000,'abc') do |player|
        a = 1
      end}.to raise_error(InternalError)
    expect(a).to eq 0
  end

end
