class ChangeCasinosColumn < ActiveRecord::Migration
  def up
    remove_column :casinos, :secret_key
    add_column :casinos, :licensee_id, :int
  end

  def down
    remove_column :casinos, :licensee_id
    add_column :casinos, :secret_key, :string, :limit => 45
  end
end
