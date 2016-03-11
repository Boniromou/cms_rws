class CreateLicensees < ActiveRecord::Migration
  def change
    create_table :licensees do |t|
      t.string :name

      t.datetime :purge_at
      t.timestamps
    end
  end
end
