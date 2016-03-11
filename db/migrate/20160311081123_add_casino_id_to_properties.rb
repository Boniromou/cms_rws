class AddCasinoIdToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :casino_id, :int
  end
end
