class RemovePlayerBalanceColumn < ActiveRecord::Migration
  def change
    remove_column :players, :balance
  end
end
