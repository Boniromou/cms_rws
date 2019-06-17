class AddTimeZoneToLicensees < ActiveRecord::Migration
  def up
    add_column :licensees, :time_zone, :string, :null => false
  end

  def down
    remove_column :licensees, :time_zone
  end
end
