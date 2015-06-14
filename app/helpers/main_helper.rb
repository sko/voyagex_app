module MainHelper
  include ::ApplicationHelper
  include ::GeoUtils
  
  def comment_attachment_to_view poi_note
    upload_entity_to_view poi_note.attachment
  end

  def upload_entity_to_view upload
    if upload.entity.is_a? UploadEntity::Mediafile
      case upload.entity.content_type.match(/^[^\/]+/)[0]
      when 'image' 
        max_width = 100
        image_tag upload.entity.file.url, style: "width:#{max_width.to_i}px;" 
      when 'audio'
        content_tag(:audio, upload.entity.id.to_s, controls: 'controls') do
          inner_html = content_tag :source, nil, src: upload.entity.file.url, type: upload.entity.file.content_type
          inner_html += 'Your browser does not support the audio element.'
          inner_html
        end
      when 'video'
        content_tag(:video, upload.entity.id.to_s, controls: 'controls') do
          inner_html = content_tag :source, nil, src: upload.entity.file.url, type: upload.entity.file.content_type
          inner_html += 'Your browser does not support the video element.'
          inner_html
        end
      else
        "unable to display entity with content_type: #{upload.entity.content_type}"
      end
    elsif upload.entity.is_a? UploadEntity::Embed
      case upload.entity.embed_type.match(/^[^\/]+/)[0]
      when 'image' 
        max_width = 100
        image_tag upload.entity.text, style: "width:#{max_width.to_i}px;" 
      else
        "unable to display entity with content_type: #{upload.entity.content_type}"
      end
    else
      'unable to display entity'
    end
  end

  def upload_entity_preview_url upload
    if upload.entity.is_a? UploadEntity::Mediafile
      case upload.entity.content_type.match(/^[^\/]+/)[0]
      when 'image' 
        upload.file.url
      when 'audio'
        VoyageX.IMAGES_PREVIEW_AUDIO_PATH
      when 'video'
        VoyageX.IMAGES_PREVIEW_VIDEO_PATH
      else
        VoyageX.IMAGES_PREVIEW_NA_PATH
      end
    elsif upload.entity.is_a? UploadEntity::Embed
      case upload.entity.embed_type.match(/^[^\/]+/)[0]
      when 'image' 
        upload.entity.text
      else
        VoyageX.IMAGES_PREVIEW_NA_PATH
      end
    else
      VoyageX.IMAGES_PREVIEW_NA_PATH
    end
  end

end
