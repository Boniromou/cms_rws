class ChangeEmployeeIdToNameInUsers < ActiveRecord::Migration
  def up
  	rename_column :users, :employee_id, :name
  end

  def down
  	rename_column :users, :name, :employee_id
  end
end