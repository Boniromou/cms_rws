class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.string :name
      t.string :secret_key
      t.string :time_zone
      t.datetime :purge_at

      t.timestamps
    end
  end
end
