class AddTimeZoneToLicensees < ActiveRecord::Migration
  def up
    add_column :licensees, :time_zone, :string
  end

  def down
    remove_column :licensees, :time_zone
  end
end
