class AddVersioningInfos < ActiveRecord::Migration
  def change
    create_table :commits do |t|
      t.integer :user_id
      t.string :hash_id
      t.datetime :timestamp
      t.integer :local_time_secs
    end
    add_index :commits, :hash_id
    add_index :commits, :timestamp
    remove_column :user_snapshots, :cur_commit_hash, :string
    add_column :user_snapshots, :commit_id, :integer
    
    now = DateTime.now
    user = User.admin
    unless user.present?
      user = User.create(username: 'admin',
                         password: 'voyagexx',
                         password_confirmation: 'voyagexx',
                         email: ADMIN_EMAIL_ADDRESS,
                         search_radius_meters: 1000,
                         foto: UserHelper::fetch_random_avatar)
    end
    vm = VersionManager.new Poi::MASTER, Poi::WORK_DIR_ROOT, user, false#@user.is_admin
    commit = user.commits.create hash_id: vm.cur_commit, timestamp: now, local_time_secs: now.to_i
    User.all.each {|u|UserSnapshot.create(user: u, location: Location.default, cur_commit: Commit.latest)}

    add_column :locations, :commit_hash, :string, nil: false
    add_column :locations, :local_time_secs, :integer
    add_column :pois, :commit_hash, :string, nil: false
    add_column :pois, :local_time_secs, :integer
    add_column :poi_notes, :commit_hash, :string, nil: false
    add_column :poi_notes, :local_time_secs, :integer
  end
end
