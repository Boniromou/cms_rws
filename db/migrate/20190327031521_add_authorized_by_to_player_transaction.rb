class AddAuthorizedByToPlayerTransaction < ActiveRecord::Migration
  def change
    add_column :player_transactions, :authorized_by, :string
    add_column :player_transactions, :authorized_at, :datetime
  end
end
