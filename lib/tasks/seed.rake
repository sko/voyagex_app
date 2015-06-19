namespace :seed do

  desc "check uploads and provide files if missing"
  task check: [:environment] do
    check_uploads
  end

  def check_uploads
    PoiNote.joins(:attachment).order(:poi_id).each do |note|
      if note.attachment.present? && note.attachment.binary?
        unless File.exist? note.attachment.entity.file.path
          puts "#{note.id}: copying dummy file to #{note.attachment.entity.file.path} ..."
          note.attachment.entity.file = File.open("#{Rails.root}/spec/support/images/foto.png", 'r')
          note.attachment.entity.save
        end
      else
        puts "#{note.id}: not binary ..."
      end
    end
    User.order(:id).each do |user|
      if user.foto.present?
        unless File.exist? user.foto.path
          puts "#{user.id}: copying dummy file to #{user.foto.path} ..."
          user.foto = File.open("#{Rails.root}/spec/support/images/foto.png", 'r')
          user.save
        end
      else
        puts "#{user.id}: no foto ..."
      end
    end
  end

end