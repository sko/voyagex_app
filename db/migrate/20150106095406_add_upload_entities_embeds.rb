class AddUploadEntitiesEmbeds < ActiveRecord::Migration
  def change
    create_table :upload_entities_embeds do |t|
      t.integer :upload_id
      t.string :embed_type
      t.text :text
      t.timestamps
    end
    add_index :upload_entities_embeds, :upload_id
  end
end
