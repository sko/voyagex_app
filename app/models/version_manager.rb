class VersionManager

  attr_reader :git_args 

  def initialize master_branch, work_dir_root, user, is_repo_owner=false
    @master = master_branch
    @user = user
    @work_dir = "#{work_dir_root}/#{user.id}#{is_repo_owner ? '_owner' : ''}"
    @git_dir = "#{@work_dir}/.git"
    @git_args = "--git-dir=#{@git_dir} --work-tree=#{@work_dir}"
    @is_repo_owner = is_repo_owner
    
    Dir.mkdir @work_dir unless File.exist? @work_dir
    unless File.exist? @git_dir
      # init_local is for testing only
      # TODO: remote
      init_local = true
      if init_local
        #File.open(File.join(@work_dir, 'README.md'), 'w+') do |f|
        #  f.write("This is the git-workdir for user #{user.id}")
        #end
        `git #{@git_args} init`
        #`git #{@git_args} checkout -b #{@master}`
        #`git #{@git_args} add README.md`
        #`git #{@git_args} commit -m 'initial commit'`
        `git #{@git_args} remote add origin #{GIT_REMOTE_URL}`
        `git #{@git_args} fetch`
        `git #{@git_args} checkout #{@master}`
        #{}`git #{@git_args} config --global credential.helper cache`
      else
        `git #{@git_args} clone https://github.com/sko/voyagex_data`
      end
    end
  end

  def work_dir
    @work_dir
  end

  def master
    @master
  end

  def is_repo_owner?
    @is_repo_owner
  end

  def cur_branch
    `git #{@git_args} branch`.match(/^\* (.+?)$/m)[1]
  end

  def cur_commit
    `git #{@git_args} rev-parse HEAD`.strip
  end

  def history
    `git #{@git_args} log --pretty=oneline | grep -o "^[^ ]\\+"`.split
  end

  def status
    branch = cur_branch
    diff = {}
    `git #{@git_args} status`.split("\n").each_with_index do |entry, idx|
      new_note_match = entry.match(/^\s*poi_([0-9]+)\/note_([0-9]+)/)
      if new_note_match.present?
        added = diff['A']
        unless added.present?
          added = {}
          diff['A'] = added
        end
        poi_notes = added[new_note_match[1]]
        unless poi_notes.present?
          poi_notes = []
          added[new_note_match[1]] = poi_notes
        end
        poi_notes << new_note_match[2] unless poi_notes.include? new_note_match[2]
      end
      del_note_match = entry.match(/^\s*deleted:\s*poi_([0-9]+)\/note_([0-9]+)/)
      if del_note_match.present?
        deleted = diff['D']
        unless deleted.present?
          deleted = {}
          diff['D'] = deleted
        end
        poi_notes = deleted[del_note_match[1]]
        unless poi_notes.present?
          poi_notes = []
          deleted[del_note_match[1]] = poi_notes
        end
        poi_notes << del_note_match[2] unless poi_notes.include? del_note_match[2]
      end
    end
    diff
  end

  # remote diff
  # {"D"=>{"136"=>["277"]}}
  def changed branch = nil
    branch = cur_branch unless branch.present?
    `git #{@git_args} fetch`
    diff = {}
    cur_change_type = nil
    `git #{@git_args} diff --name-status #{branch}..origin/#{branch}`.split.each_with_index do |entry, idx|
      if idx%2==0
        # 'A'|'M'|'D'
        cur_change_type = diff[entry]
        unless cur_change_type.present?
          cur_change_type = {}
          diff[entry] = cur_change_type
        end
      else
        # start match from lowest level 
        match = entry.match(/^poi_([0-9]+)\/(data|note_([0-9]+))/)
        poi_change_data = cur_change_type[match[1]]
        unless poi_change_data.present?
          poi_change_data = []
          cur_change_type[match[1]] = poi_change_data
        end
        if match[2] == 'data'
          # poi-change
          poi_change_data << 'self' unless poi_change_data.include?('self')
        else
          # poi_note-change
          poi_change_data << match[3] unless poi_change_data.include?(match[3])
        end
      end
    end
    diff
  end

  def first_commit file
    `git #{@git_args} log --pretty=oneline --diff-filter=A -- #{file} | grep -o "^[^ ]\\+"`.strip
  end

  def files_commited commit_hash
    `git #{@git_args} show --pretty="format:" --name-only #{commit_hash}`.split
  end

  #
  # forwards to #{commit_hash} of master
  # can check files with git update-ref -m "forward" refs/heads/test/master f8b3d41343a12c39bdefdad4b2ebaa98e5d7c15d
  #
  def forward commit_hash
    `git #{@git_args} fetch`
    `git #{@git_args} rebase --onto #{commit_hash} #{cur_commit}`
  end

  #
  # forwards to HEAD of master
  #
  def fast_forward
    `git #{@git_args} fetch`
    `git #{@git_args} rebase origin/#{@master}`
  end

  def set_branch branch
    return unless branch.present?
    if cur_branch != branch
      push cur_branch
      if `git #{@git_args} branch`.match(/^\s+#{branch}$/m).present?
        `git #{@git_args} checkout #{branch}`
      else
        `git #{@git_args} checkout -b #{branch}`
      end
    end
  end

  def add_file file
    `git #{@git_args} add #{file}`
    `git #{@git_args} commit -m '-'`
  end

  def merge add_all = false, push = false
    branch = cur_branch
    if add_all
      `git #{@git_args} add -A`
      `git #{@git_args} commit -m 'user #{@user.id} merging #{cur_branch}'`
    end
    `git #{@git_args} fetch`
    #`git #{@git_args} merge #{@master}`
    #`git #{@git_args} merge -s resolve #{@master}`
    `git #{@git_args} rebase origin/#{@master}`
    set_branch @master
    `git #{@git_args} merge #{branch}`
    `git #{@git_args} push origin #{branch}` if push
    set_branch branch
  end

  def push branch=nil
    branch = @master unless branch.present? 
    `git #{@git_args} add -u`
    `git #{@git_args} commit -m 'user #{@user.id} pushing #{cur_branch}'`
    `git #{@git_args} fetch`
    # next might fatal: Needed a single revision and invalid upstream origin/#{branch} if branch doesn't exist
    `git #{@git_args} rebase origin/#{branch}`
    `git #{@git_args} push origin #{branch}`
  end

  def add_and_merge_file file
    add_file file
    merge
  end

  def add_poi poi, poi_dir = nil
    unless poi_dir.present?
      poi_dir = "#{work_dir}/poi_#{poi.id}" 
      return false if File.exist? poi_dir
    end
    Dir.mkdir poi_dir 
    data  = <<data
{
  location_id: #{poi.location.id}
}
data
    file = File.join(poi_dir, 'data')
    File.open(file, 'w+') { |f| f.write(data) }
  end

  def add_poi_note poi, note, note_dir = nil
    unless note_dir.present?
      note_dir = "#{work_dir}/poi_#{poi.id}/note_#{note.id}"
      return false if File.exist? note_dir
    end
    Dir.mkdir note_dir 
    data  = <<data
{
  user_id: #{note.user.id}
  text: '#{note.text.gsub(/'/, "\\\'").gsub(/\n/, '\\\n').gsub(/\r/, '\\\r')}'
  comments_on_id: #{note.comments_on_id}
  created_at: #{note.created_at}
  updated_at: #{note.updated_at}
}
data
    file = File.join(note_dir, 'data')
    File.open(file, 'w+') { |f| f.write(data) }
    
    add_attachment poi, note if note.attachment.present?
  end

  def add_attachment poi, note, attachment_dir = nil
    unless attachment_dir.present?
      attachment_dir = "#{work_dir}/poi_#{poi.id}/note_#{note.id}/attachment"
      return false if File.exist? attachment_dir
    end
    Dir.mkdir attachment_dir 
    data  = <<data
{
  created_at: #{note.attachment.created_at}
  updated_at: #{note.attachment.updated_at}
}
data
    file = File.join(attachment_dir, 'data')
    File.open(file, 'w+') { |f| f.write(data) }
  end

  def delete_poi poi_id
    poi_dir = "#{work_dir}/poi_#{poi_id}" 
    return false unless File.exist? poi_dir
    FileUtils.rm_rf poi_dir
  end

  def delete_poi_note poi_id, poi_note_id
    poi_dir = "#{work_dir}/poi_#{poi_id}" 
    return false unless File.exist? poi_dir
    poi_note_dir = "#{poi_dir}/note_#{poi_note_id}"
    return false unless File.exist? poi_note_dir
    FileUtils.rm_rf poi_note_dir
  end

  def self.init_version_control_from_db
    master = Poi::MASTER # 'model/master'
    work_dir_root = Poi::WORK_DIR_ROOT # "#{Rails.root}/version_control"
    admin = User.admin
    vm = VersionManager.new master, work_dir_root, admin
    ## user and location will actually not change
    #Location.all.each do |location|
    #  location_dir = "#{vm.work_dir}/location_#{location.id}"
    #  vm.add_location location, location_dir unless File.exist? location_dir
    #end
    Poi.all.each do |poi|
      poi_dir = "#{vm.work_dir}/poi_#{poi.id}"
     vm.add_poi poi, poi_dir unless File.exist? poi_dir
      poi.notes.each do |note|
        note_dir = "#{vm.work_dir}/poi_#{poi.id}/note_#{note.id}"
        vm.add_poi_note poi, note, note_dir unless File.exist? note_dir
      end
    end
    `git #{vm.git_args} add -A`
    `git #{vm.git_args} commit -m 'commit before changing branch'`
    `git #{vm.git_args} push origin #{@master}`
  end

end
