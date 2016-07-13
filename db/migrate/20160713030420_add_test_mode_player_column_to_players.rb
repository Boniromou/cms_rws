class AddTestModePlayerColumnToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :test_mode_player, :boolean, :default => false
  end
end
