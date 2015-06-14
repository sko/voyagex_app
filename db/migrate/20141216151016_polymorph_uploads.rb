class PolymorphUploads < ActiveRecord::Migration

  def up
    create_table :pois do |t|
      t.integer :location_id
      t.timestamps
    end

    create_table :poi_notes do |t|
      t.integer :poi_id
      t.integer :user_id
      t.text :text
      t.integer :comments_on_id
      t.integer :attachment_id
      t.timestamps
    end
    add_index :poi_notes, :poi_id
    add_index :poi_notes, :user_id
    add_index :poi_notes, :comments_on_id

    drop_table :upload_comments

    create_table :upload_entities_mediafiles do |t|
      t.integer :upload_id
      t.attachment :file
      t.timestamps
    end
    add_index :upload_entities_mediafiles, :upload_id

    remove_index :uploads, :location_id
    remove_column :uploads, :location_id
    remove_index :uploads, :user_id
    remove_column :uploads, :user_id
    remove_attachment :uploads, :file
    add_reference :uploads, :poi_note
    add_reference :uploads, :entity, polymorphic: true, index: true
  end

  def down
    remove_reference :uploads, :entity, polymorphic: true
    remove_reference :uploads, :poi_note
    add_attachment :uploads, :file
    add_column :uploads, :user_id, :integer
    add_index :uploads, :user_id
    add_column :uploads, :location_id, :integer
    add_index :uploads, :location_id
    drop_table :upload_entities_mediafiles
    create_table :upload_comments do |t|
      t.integer :user_id, null: false
      t.integer :upload_id
      t.text :text
      t.timestamps
    end
    add_index :upload_comments, :user_id
    add_index :upload_comments, :upload_id
    drop_table :poi_notes
    drop_table :pois
  end

end
