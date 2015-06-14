class AddFotoToUser < ActiveRecord::Migration
  def change
    add_attachment :users, :foto
  end
end
