class AddCommitRef < ActiveRecord::Migration
  
  def up
    add_reference :locations, :commit, index: true
    add_reference :pois, :commit, index: true
    add_reference :poi_notes, :commit, index: true

    Location.all.each do |l|
      commit = Commit.where(hash_id: l.commit_hash).first
      l.update_attribute :commit_id, commit.id if commit.present?
    end
    Poi.all.each do |p|
      commit = Commit.where(hash_id: p.commit_hash).first
      p.update_attribute :commit_id, commit.id if commit.present?
    end
    PoiNote.all.each do |p_n|
      commit = Commit.where(hash_id: p_n.commit_hash).first
      p_n.update_attribute :commit_id, commit.id if commit.present?
    end
    
    remove_column :locations, :commit_hash
    remove_column :pois, :commit_hash
    remove_column :poi_notes, :commit_hash
    remove_column :poi_notes, :user_id
  end

  def down
    add_column :poi_notes, :user_id, :integer, nil: false
    add_column :poi_notes, :commit_hash, :string, nil: false
    add_column :pois, :commit_hash, :string, nil: false
    add_column :locations, :commit_hash, :string, nil: false

    PoiNote.all.each do |p_n|
      p_n.update_attributes user_id: p_n.commit.user.id, commit_hash: p_n.commit.hash_id if p_n.commit.present?
    end
    Poi.all.each do |p|
      p.update_attribute :commit_hash, p.commit.hash_id if p.commit.present?
    end
    Location.all.each do |l|
      l.update_attribute :commit_hash, l.commit.hash_id if l.commit.present?
    end

    remove_reference :poi_notes, :commit
    remove_reference :pois, :commit
    remove_reference :locations, :commit
  end

end
