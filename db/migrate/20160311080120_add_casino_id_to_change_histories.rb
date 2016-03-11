class AddCasinoIdToChangeHistories < ActiveRecord::Migration
  def change
    add_column :change_histories, :casino_id, :int
  end
end
