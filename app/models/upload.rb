class Upload < ActiveRecord::Base
  belongs_to :attached_to, class_name: 'PoiNote', foreign_key: :poi_note_id#, inverse_of: :attachment
  belongs_to :entity, polymorphic: true, dependent: :destroy
  belongs_to :mediafile, -> { where uploads: {entity_type: 'UploadEntity::Mediafile'} }, class_name: 'UploadEntity::Mediafile', foreign_key: :entity_id#, inverse_of: :attachment
  belongs_to :embed, -> { where uploads: {entity_type: 'UploadEntity::Embed'} }, class_name: 'UploadEntity::Embed', foreign_key: :entity_id#, inverse_of: :attachment

  validates :entity, presence: true
  validates_associated :entity
  
  def file
    entity.file
  end
  
  def binary?
    ['UploadEntity::Mediafile'].include? entity_type
  end

  def build_entity content_type, build_params = {}
    case content_type.to_s.match(/^[^:\/]+/)[0]
    when 'audio'
      self.entity = UploadEntity::Mediafile.new(build_params.merge!(upload: self))
    when 'image'
      self.entity = UploadEntity::Mediafile.new(build_params.merge!(upload: self))
    when 'video'
      self.entity = UploadEntity::Mediafile.new(build_params.merge!(upload: self))
    when 'embed'
      self.entity = UploadEntity::Embed.new(build_params.merge!(upload: self))
    else
    end
  end

  # imagemagick complains about image/webp and .webp
  def self.get_attachment_mapping content_type
    case content_type
    when 'image/webp'
      return ['application/octet-stream', 'class']
    else
      return [content_type]
    end
  end
end
