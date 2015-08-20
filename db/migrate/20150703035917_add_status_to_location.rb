class AddStatusToLocation < ActiveRecord::Migration
  def change
  	add_column :locations, :status, :string
  	add_column :stations, :status, :string
  end
end
