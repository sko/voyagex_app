class UserSnapshot < ActiveRecord::Base
  belongs_to :user, inverse_of: :snapshot
  belongs_to :location
  belongs_to :cur_commit, class_name: 'Commit', foreign_key: :commit_id

  after_save :check_location

  private

  #
  #
  #
  def check_location
    if location.present? && location.persisted? && (lat.present? || lng.present?)
      update_attributes lat: nil, lng: nil
    end
  end

end
