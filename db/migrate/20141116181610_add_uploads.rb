class AddUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.integer :user_id, null: false
      t.integer :location_id
      t.attachment :file

      t.timestamps
    end
    add_index :uploads, :user_id
    add_index :uploads, :location_id
  end
end
