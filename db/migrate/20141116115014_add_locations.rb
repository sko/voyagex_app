class AddLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.decimal :latitude, :precision => 10, :scale => 7, nil: false
      t.decimal :longitude, :precision => 10, :scale => 7, nil: false
      t.text :address

      t.timestamps
    end
    add_index :locations, [:latitude, :longitude]

    create_table :locations_users do |t|
      t.integer :location_id
      t.integer :user_id

      t.timestamps
    end
    add_index :locations_users, :location_id
    add_index :locations_users, :user_id
  end
end
