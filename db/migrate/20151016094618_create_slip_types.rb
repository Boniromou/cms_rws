class CreateSlipTypes < ActiveRecord::Migration
  def change
    create_table :slip_types do |t|
      t.string :name, :null => false
      t.datetime :purge_at

      t.timestamps
    end
  end
end
