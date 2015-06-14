class AddUploadComments < ActiveRecord::Migration
  def change
    create_table :upload_comments do |t|
      t.integer :user_id, null: false
      t.integer :upload_id
      t.text :text

      t.timestamps
    end
    add_index :upload_comments, :user_id
    add_index :upload_comments, :upload_id
  end
end
