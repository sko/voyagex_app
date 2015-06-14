class AddCommPorts < ActiveRecord::Migration
  def change
    create_table :comm_ports do |t|
      t.integer :user_id, null: false
      t.string :channel_enc_key, null: false

      t.timestamps
    end
    add_index :comm_ports, :user_id
    add_index :comm_ports, :channel_enc_key
    
    create_table :comm_peers do |t|
      t.integer :comm_port_id, null: false
      t.integer :peer_id, null: false

      t.timestamps
    end
    add_index :comm_peers, :comm_port_id
  end
end
