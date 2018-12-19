class ChangeConfigValueSize<ActiveRecord::Migration
  def up
    change_column :configurations, :value, :string, :limit => 256
  end
  
  def down
    change_column :configurations, :value, :string, :limit => 40
  end 
end
