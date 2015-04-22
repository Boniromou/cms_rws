class CreateRoundTransactions < ActiveRecord::Migration
  def up
    create_table :round_transactions do |t|
      t.string :ref_trans_id, null: false
      t.integer :bet_amt
      t.integer :payout_amt
      t.integer :win_amt
      t.integer :before_balance
      t.integer :after_balance
      t.string :aasm_state
      t.string :trans_type, null: false
      t.datetime :trans_date
      t.integer :round_id
      t.integer :internal_game_id
      t.integer :external_game_id
      t.decimal :pc_jp_con_amt, precision: 25, scale: 10
      t.decimal :pc_jp_win_amt, precision: 25, scale: 10
      t.decimal :jc_jp_con_amt, precision: 25, scale: 10
      t.decimal :jc_jp_win_amt, precision: 25, scale: 10
      t.string :jp_win_id
      t.integer :jp_win_lev
      t.integer :jp_direct_pay
      t.integer :property_id, null: false
      t.integer :player_id, null: false
      t.datetime :purge_at

      t.timestamps
    end
    change_column :round_transactions, :id, :bigint
    change_column :round_transactions, :bet_amt, :bigint
    change_column :round_transactions, :payout_amt, :bigint
    change_column :round_transactions, :win_amt, :bigint
    change_column :round_transactions, :before_balance, :bigint
    change_column :round_transactions, :after_balance, :bigint
    change_column :round_transactions, :round_id, :bigint
    change_column :round_transactions, :jp_direct_pay, :tinyint

    execute "ALTER TABLE round_transactions ADD CONSTRAINT fk_round_trans_player_id FOREIGN KEY (player_id) REFERENCES players(id);"
  end

  def down
    execute "ALTER TABLE round_transactions DROP FOREIGN KEY fk_round_trans_player_id;"
    drop_table :round_transactions
  end
end
