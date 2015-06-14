class AddNotesToLocationsUsers < ActiveRecord::Migration
  def change
    add_column :locations_users, :note, :text
  end
end
