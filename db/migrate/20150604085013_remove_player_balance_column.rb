class RemovePlayerBalanceColumn < ActiveRecord::Migration
  def up
    remove_column :players, :balance
  end

  def down
    add_column :players, :balance, :bigint
  end
end
