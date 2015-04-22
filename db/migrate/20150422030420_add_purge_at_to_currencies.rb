class AddPurgeAtToCurrencies < ActiveRecord::Migration
  def change
    add_column :currencies, :purge_at, :datetime
  end
end
