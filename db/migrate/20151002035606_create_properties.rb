class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.string :name,:null => false, :limit => 45
      t.string :secret_key,:null => false, :limit => 45

      t.timestamps
    end
  end
end
