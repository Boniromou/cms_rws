class AddCasinoFromUsers < ActiveRecord::Migration
  def up
    add_column :users, :casino_id, :int, :null => true
  end
  
  def down
    remove_column :users, :casino_id
  end
end
