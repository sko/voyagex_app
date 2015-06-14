class PoiNote < ActiveRecord::Base
  belongs_to :commit#, dependent: :destroy
  belongs_to :poi
  belongs_to :attachment, class_name: 'Upload', inverse_of: :attached_to, dependent: :destroy
  belongs_to :comments_on, class_name: 'PoiNote'
  has_many :comments, class_name: 'PoiNote', foreign_key: :comments_on_id, dependent: :destroy
  
  validates_associated :attachment, if: Proc.new { |note| note.attachment.present? }

  def user
    commit.user
  end

end
