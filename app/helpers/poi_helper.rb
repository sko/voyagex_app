module PoiHelper
  include ::GeoUtils

  def add_attachment_to_poi_note_json upload, poi_note_json
    if upload.entity.is_a? UploadEntity::Mediafile
      case upload.entity.content_type.match(/^[^\/]+/)[0]
      when 'image'
        geometry = Paperclip::Geometry.from_file(upload.entity.file)
        poi_note_json[:attachment] = { content_type: upload.entity.file.content_type, id: upload.id, url: upload.entity.file.url, width: geometry.width.to_i, height: geometry.height.to_i }
      when 'audio'
        poi_note_json[:attachment] = { content_type: upload.entity.file.content_type, id: upload.id, url: upload.entity.file.url }
      when 'video'
        poi_note_json[:attachment] = { content_type: upload.entity.file.content_type, id: upload.id, url: upload.entity.file.url }
      else
        poi_note_json[:attachment] = { content_type: 'unknown/unknown', id: upload.id, url: upload.entity.file.url }
      end
    elsif upload.entity.is_a? UploadEntity::Embed
      case upload.entity.embed_type.match(/^[^\/]+/)[0]
      when 'image'
        poi_note_json[:attachment] = { content_type: "embed:#{upload.entity.embed_type}", id: upload.id, content: upload.entity.text, width: -1, height: -1 }
      when 'audio'
        poi_note_json[:attachment] = { content_type: "embed:#{upload.entity.embed_type}", id: upload.id, content: upload.entity.text }
      when 'video'
        poi_note_json[:attachment] = { content_type: "embed:#{upload.entity.embed_type}", id: upload.id, content: upload.entity.text }
      else
        poi_note_json[:attachment] = { content_type: 'embed:unknown/unknown', id: upload.id, content: upload.entity.text }
      end
    else
      poi_note_json[:attachment] = { content_type: 'unknown/unknown', id: upload.id, url: nil, width: -1, height: -1 }
    end
  end
  
  def poi_json poi
    poi_json = { id: poi.id,
                 lat: poi.location.latitude,
                 lng: poi.location.longitude,
                 address: shorten_address(poi.location),
                 locationId: poi.location.id }
  end
  
  def poi_note_json poi_note, with_poi = true
    poi_note_json = { id: poi_note.id,
                      user: { id: poi_note.user.id,
                              username: poi_note.user.username },
                      text: poi_note.text }
    poi_note_json[:poi] = poi_json poi_note.poi if with_poi
    add_attachment_to_poi_note_json poi_note.attachment, poi_note_json if poi_note.attachment.present?
    poi_note_json
  end

  def poi_notes_as_list poi, poi_note
    poi_notes = []
    poi.notes.where('comments_on_id is null').each do |p_n|
      poi_notes << poi_note_json(p_n, false)
      p_n.comments.each do |p_n_2|
        poi_notes << poi_note_json(p_n_2, false)
        if poi_note.present? && p_n_2 == poi_note
          # only recurse for requested
          addToThread poi_note, poi_notes
        end
      end
    end
    poi_notes
  end

  def addToThread poi_note, comments
    poi_note.comments.each do |p_n|
      comments << poi_note_json(p_n, false)
      addToThread p_n, comments
    end
  end

end