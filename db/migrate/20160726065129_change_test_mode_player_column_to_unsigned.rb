class ChangeTestModePlayerColumnToUnsigned < ActiveRecord::Migration
  def up
    change_column :players, :test_mode_player,"TINYINT(1) UNSIGNED NOT NULL", :default => 0
  end

  def down
    change_column :players, :test_mode_player,"TINYINT(1) SIGNED NOT NULL", :default => 0
  end
end
