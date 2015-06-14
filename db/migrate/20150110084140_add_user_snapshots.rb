class AddUserSnapshots < ActiveRecord::Migration
  def change
    create_table :user_snapshots do |t|
      t.integer :user_id
      t.integer :location_id
      t.decimal :lat, :precision => 10, :scale => 7
      t.decimal :lng, :precision => 10, :scale => 7
      t.string :address
      t.string :cur_commit_hash
      t.timestamps
    end
    add_index :user_snapshots, :user_id

    add_column :comm_peers, :note_follower, :text
    add_column :comm_peers, :note_followed, :text
  end
end
