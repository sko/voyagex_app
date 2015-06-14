class AddIdentities < ActiveRecord::Migration
  def change
    create_table :identities do |t|
      t.integer :user_id, null: false
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.string :email_is_confirmed
      t.string :auth_token
      t.datetime :auth_token_expires_at
      t.string :auth_secret
      t.timestamps
    end
    add_index :identities, [:user_id]
    add_index :identities, [:provider, :uid]
    
    create_table :groups do |t|
      t.string :name, null: false
      t.integer :creator_id, null: false
      t.timestamps
    end
    
    create_table :users_groups do |t|
      t.integer :user_id, null: false
      t.integer :group_id, null: false
      t.integer :invitation_sender_id, null: false
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.timestamps
    end
    add_index :users_groups, [:user_id]
    add_index :users_groups, [:group_id]
  end
end
