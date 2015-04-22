class CreatePlayerInfos < ActiveRecord::Migration
  def up
    create_table :player_infos do |t|
      t.string :player_name
      t.string :member_id
      t.string :card_id
      t.integer :player_id

      t.timestamps
    end
    add_index(:player_infos, :member_id, unique:true, name: 'by_member_id')
    add_index(:player_infos, :card_id, unique:true, name: 'by_card_id')
    execute "ALTER TABLE player_infos ADD CONSTRAINT fk_info_player_id FOREIGN KEY (player_id) REFERENCES players(id);"
  end

  def down
    execute "ALTER TABLE player_infos DROP FOREIGN KEY fk_info_player_id;"
    drop_table :player_infos
  end
end
