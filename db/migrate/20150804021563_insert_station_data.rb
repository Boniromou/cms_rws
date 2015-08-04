class InsertStationData < ActiveRecord::Migration
  def up
    Station.delete_all
    Location.delete_all
    execute "INSERT INTO locations(id, name, status, created_at, updated_at) values(1, 'LOCATION1', 'active', '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO stations(id, name, status, location_id, created_at, updated_at) values(1, 'STATION1', 'active', 1, '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    Station.delete_all
    Location.delete_all
  end
end
