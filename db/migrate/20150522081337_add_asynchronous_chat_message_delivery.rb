class AddAsynchronousChatMessageDelivery < ActiveRecord::Migration
  def change
    remove_index :chat_messages, :user_id
    rename_column :chat_messages, :user_id, :sender_id
    add_index :chat_messages, :sender_id
    add_column :chat_messages, :p2p_receiver_id, :integer

    create_table :chat_message_deliveries do |t|
      t.integer :subscriber_id, null: false
      t.string :channel # /talk@o74s558g2
      t.integer :last_message_id
      t.datetime :created_at
    end
    add_index :chat_message_deliveries, :subscriber_id
  end
end
