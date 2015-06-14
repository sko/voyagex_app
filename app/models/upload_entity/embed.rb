class UploadEntity::Embed < ActiveRecord::Base
  self.table_name = 'upload_entities_embeds'
  
  #belongs_to :upload, inverse_of: :entity
  belongs_to :upload, inverse_of: :embed
  
  validates :upload, presence: true
  validates :text, presence: true
  validates :embed_type, presence: true

  def file
    Struct.new(:url, :content_type).new text, "embed:#{UploadEntity::Embed.get_embed_type(text)}"
  end

  def self.get_embed_type text
    if text.match(/^</).present?
      # youtube, ...
    else
      suffixMatch = text.match(/[^.]+$/)
      if suffixMatch.present?
        if ['jpg','jpeg','gif','png','webp'].include?(suffixMatch[0])
          return "image/#{suffixMatch[0]}"
        else
        end
      end
    end
    nil
  end
end
