class ChangeMachineIdToTerminalId < ActiveRecord::Migration
  def up
  	rename_column :stations, :machine_id, :terminal_id
  end

  def down
  	rename_column :stations, :terminal_id, :machine_id
  end
end
