class AddChatMessages < ActiveRecord::Migration
  def change
    create_table :chat_messages do |t|
      t.integer :user_id, null: false
      t.text :text
      t.datetime :created_at
    end
    add_index :chat_messages, :user_id
  end
end
