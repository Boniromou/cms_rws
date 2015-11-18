class CreateConfigurations < ActiveRecord::Migration
  def up
  	create_table :configurations do |t|
      t.integer :property_id, :null => false
      t.string :key, :null => false, :limit => 45
      t.string :value, :null => false, :limit => 45
      t.string :description, :limit => 45

      t.timestamps
    end
    execute "ALTER TABLE configurations ADD CONSTRAINT fk_configurations_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
    add_index :configurations, [:property_id, :key], :unique => true
  end

  def down
  	drop_table :configurations
  end
end
