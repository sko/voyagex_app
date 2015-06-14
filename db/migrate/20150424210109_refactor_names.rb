class RefactorNames < ActiveRecord::Migration

  def change
    rename_column :comm_peers, :granted_by_peer, :granted_by_user
  end

end
