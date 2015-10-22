class CreateChangeHistories < ActiveRecord::Migration
  def up
  	create_table :change_histories do |t|
      t.string :action_by, :null => false, :limit => 45
      t.string :object, :null => false, :limit => 45
      t.string :action, :null => false, :limit => 45
      t.string :change_detail, :null => false, :limit => 255
      t.integer :property_id, :null => false
      t.datetime :action_at, :null => false

      t.timestamps
    end
    execute "ALTER TABLE change_histories ADD CONSTRAINT fk_change_histories_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
  end

  def down
  	drop_table :change_histories
  end
end
