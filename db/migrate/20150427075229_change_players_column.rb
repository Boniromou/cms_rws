class ChangePlayersColumn < ActiveRecord::Migration
  def up
    Player.delete_all
    change_column :players, :balance, :bigint
  end

  def down
    change_column :players, :balance, :int
  end
end
