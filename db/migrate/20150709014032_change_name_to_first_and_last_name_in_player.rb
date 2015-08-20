class ChangeNameToFirstAndLastNameInPlayer < ActiveRecord::Migration
  def up
  	add_column :players, :first_name, :string
    add_column :players, :last_name, :string
    remove_column :players, :player_name
  end

  def down
  	remove_column :players, :first_name
    remove_column :players, :last_name
    add_column :players, :player_name, :string
  end
end
