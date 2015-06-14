require 'spec_helper'

#
# wd=`pwd` && cd spec/tmp/serializer && gitk && cd $wd
#
describe 'Serializer', vcr: true do

  TEST_MASTER = true

  before(:each) do
    @v_m_u_master = VersionManager.new SPEC_MASTER, WORK_DIR_ROOT, FactoryGirl.create(:user), true
    delete_branch SPEC_MASTER, @v_m_u_master, true
    init_master
    unless TEST_MASTER
    @v_m_u_1 = VersionManager.new SPEC_MASTER, WORK_DIR_ROOT, FactoryGirl.create(:user)
    @v_m_u_2 = VersionManager.new SPEC_MASTER, WORK_DIR_ROOT, FactoryGirl.create(:user)
    end
    @start_branch = @v_m_u_master.cur_branch
  end

  after(:each) do
    @v_m_u_master.set_branch @start_branch||SPEC_MASTER
    unless TEST_MASTER
    @v_m_u_1.set_branch @start_branch
    @v_m_u_2.set_branch @start_branch
    end
  end

  describe '#' do
    it 'creates a dashboard entry' do
#PoiNote(id: integer, poi_id: integer, user_id: integer, text: text, comments_on_id: integer, attachment_id: integer, created_at: datetime, updated_at: datetime)
      unless TEST_MASTER
      v1_branch = 'spec/v1'
      @v_m_u_1.set_branch v1_branch
      v1  = <<v1
[
add poi_note 1.1
add poi_note 1.2
]
v1
      v1_file = File.join(@v_m_u_1.work_dir, 'serialized')
      File.open(v1_file, 'w+') { |f| f.write(v1) }
      @v_m_u_1.add_and_merge_file v1_file
      @v_m_u_1.push

      v2_branch = 'spec/v1'
      @v_m_u_2.set_branch v2_branch
      v2  = <<v2
[
add poi_note 2.1
add poi_note 2.2
]
v2
      v2_file = File.join(@v_m_u_2.work_dir, 'serialized')
      File.open(v2_file, 'w+') { |f| f.write(v2) }
      @v_m_u_2.add_and_merge_file v2_file
      @v_m_u_2.push
      end
    end
  end

  private
    
  def init_master
    m1  = <<m1
[
]
m1
    m1_file = File.join(@v_m_u_master.work_dir, 'serialized')
    File.open(m1_file, 'w+') { |f| f.write(m1) }
    @v_m_u_master.add_and_merge_file m1_file
    @v_m_u_master.push
  end

  # only used for testing
  def delete_branch branch, version_manager, force = false
    git_args = "--git-dir=#{version_manager.work_dir}/.git --work-tree=#{version_manager.work_dir}"
    if branch == version_manager.master
      if force
        `git #{git_args} checkout -b tmp/delete-other-branches`
      else
        puts "------------ not allowed to delete master #{branch}"
        return
      end
    end
    `git #{git_args} branch -D #{branch}`
    `git #{git_args} push origin :#{branch}` if version_manager.is_repo_owner?
    #`git #{git_args} remote prune #{branch}`
    if branch == version_manager.master
      # TODO delete all other branches (they ar branched from master)
      `git #{git_args} branch`.split('\n').each do |b|
        b = b.match(/\*?\s+(.+)/)[1]
        next if b == version_manager.master || b.match(/^tmp\//).present?
        puts "------------ b = #{b}"
        delete_branch b, version_manager
      end
      puts "------------ reinit master: #{branch}"
      `git #{git_args} checkout -b #{branch}`
      `git #{git_args} branch -D tmp/delete-other-branches` if branch == version_manager.master
    end
  end

end 
