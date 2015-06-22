#require 'faye'
class PostCommit
  include PoiHelper

  LOGGER = Logger.new("#{Rails.root}/log/post_commit.log")

  # queue for resque
  @queue = :post_commit

  # callback for resque-worker
  def self.perform *args
    args_hash = args.first
    case args_hash['action']
      when 'sync_pois'
        PostCommit.sync_pois args_hash['commit_id'], args_hash['modified_poi_data']
      when 'delete_poi'
        PostCommit.delete_poi args_hash['user_id'], args_hash['poi_id']
      when 'pull_pois'
        PostCommit.pull_pois args_hash['user_id'], args_hash['commit_hash']
    end
  end

  def self.pull_pois user_id, commit_hash
    PostCommit.new.pull_pois user_id, commit_hash
  end

  #
  # read only - for write/commit @see sync_pois
  #
  def pull_pois user_id, commit_hash, fork_publish = true
    #LOGGER.debug "pull_pois: ENV['USER'] = #{ENV['USER']}"
    LOGGER.debug "pull_pois: user_id = #{user_id}, commit_hash = #{commit_hash}"
    @user = User.find user_id
    location = @user.snapshot.location.present? ? @user.snapshot.location : Location.new(latitude: @user.snapshot.lat, longitude: @user.snapshot.lng)
    ls_c = lat_lng_limits location.latitude, location.longitude, @user.search_radius_meters

    vm = VersionManager.new Poi::MASTER, Poi::WORK_DIR_ROOT, @user, false#@user.is_admin?
    prev_commit = vm.cur_commit
    #LOGGER.debug "pull_pois: vm.cur_commit = #{vm.cur_commit}, vm.status = #{vm.status}"

    if prev_commit != commit_hash
      # scenario:
      # a user pulls from a different client with an earlier state than user's latest commit
      vm.forward commit_hash
      prev_commit = commit_hash
    end
    
    @new_pois = {}
    @modified_pois = {}
    @deleted_pois = []

    diff = vm.changed
    # TODO - M (edit)
    diff_added = diff['A']
    diff_modified = diff['M']
    diff_deleted = diff['D']

    if diff_added.present?
      diff_added.each do |poi_id, note_ids|
        is_new_poi = note_ids.delete('self').present?
        cur_poi = nil
        note_ids.each_with_index do |note_id, idx|
          poi_note = PoiNote.find note_id
          unless cur_poi.present?
            # out-of-range-poi
            break unless within_limits(poi_note.poi.location.latitude, poi_note.poi.location.longitude, ls_c)
            cur_poi = poi_note.poi
          end
          note_ids[idx] = poi_note_json(poi_note, false)
        end
        # out-of-range-poi is nil
        next unless cur_poi.present?
        if is_new_poi
          poi_json = poi_json cur_poi
          poi_json.delete :id
          @new_pois[poi_id.to_i] = { notes: note_ids }.merge!(poi_json)
        else
          @modified_pois[poi_id.to_i] = { notes: note_ids }
        end
      end
    end

    if diff_deleted.present?
      diff_deleted.each do |poi_id, note_ids|
        delete_poi = note_ids.delete('self').present?
        if delete_poi
          @deleted_pois << poi_id.to_i
          next
        end
        cur_poi_note_ids = []
        note_ids.each_with_index do |note_id, idx|
          cur_poi_note_ids << { id: -note_id.to_i }
        end
        poi_data = @modified_pois[poi_id.to_i]
        unless poi_data.present?
          @modified_pois[poi_id.to_i] = { notes: [] }
        end
        @modified_pois[poi_id.to_i][:notes].concat cur_poi_note_ids
      end
    end

    vm.fast_forward
    cur_commit = vm.cur_commit
    commit = Commit.where(hash_id: cur_commit).first
    @user.snapshot.update_attribute :cur_commit, commit

    system_msg_for_user = { type: 'callback',
                            channel: 'pois',
                            action: 'pull',
                            commit_hash: cur_commit,
                            new_pois: @new_pois,
                            modified_pois: @modified_pois,
                            deleted_pois: @deleted_pois }

    msgs_data = [
                  { channel: "/system#{PEER_CHANNEL_PREFIX}#{@user.comm_port.sys_channel_enc_key}",
                    msg: system_msg_for_user,
                    user_id: @user.id }
                ]
    Publisher.new.publish msgs_data, fork_publish
  end

  # updates the users repository:
  # 1) pulls data meanwhile created by other users 
  # 2) pushes data created by this user (vm)
  def self.sync_pois commit_id, modified_poi_data
    PostCommit.new.sync_pois commit_id, modified_poi_data
  end

  # Parameters: {"pois"=>{"-1433919822"=>{"location"=>{"latitude"=>"52.4939386", "longitude"=>"13.4382749"},
  #                                       "notes"=>{"-1433919822"=>{"text"=>"3", "action"=>"create"}}},
  #                       "-1433919815"=>{"location"=>{"latitude"=>"52.4941215", "longitude"=>"13.4317088"},
  #                                       "notes"=>{"-1433919815"=>{"text"=>"1", "action"=>"create"},
  #                                                 "-1433919818"=>{"text"=>"2", "action"=>"create"}}}}, 
  def sync_pois commit_id, modified_poi_data, fork_publish = true
    #LOGGER.debug "sync_pois: ENV['USER'] = #{ENV['USER']}"
    LOGGER.debug "sync_pois: commit_id = #{commit_id}, modified_poi_data = #{modified_poi_data}"
    #LOGGER.debug "sync_pois: ENV['USER'] = #{ENV['USER']}"
    commit = Commit.find commit_id
    @user = commit.user
    
    vm = VersionManager.new Poi::MASTER, Poi::WORK_DIR_ROOT, @user, false#@user.is_admin?
    #LOGGER.debug "sync_pois: vm.cur_commit = #{vm.cur_commit}, vm.status = #{vm.status}"

    diff = vm.changed
    diff_added = diff['A']
    diff_deleted = diff['D']

    errors = []
    poi_jsons = []
    # for collecting broadcasted system-sync-messages
    @poi_jsons_for_user = []
    @poi_jsons_for_others = []

    modified_poi_data.each do |poi_id, modified_note_data|
      if modified_note_data['deleted'] == true
        vm.delete_poi poi_id
        @poi_jsons_for_user << { id: -poi_id.to_i, user: { id: @user.id } }
        # others will just be notified that poi changed and the should pull request if lat/lng is in their range
        @poi_jsons_for_others << { poi_id: poi_id.to_i, lat: modified_note_data['poi_location_latitude'], lng: modified_note_data['poi_location_longitude'] }
        next
      end
      poi = Poi.find poi_id
      is_new_poi = (poi.commit == commit)
      # is new by current_user or other - either way it must be added to vm
      # if poi was deleted meanwhile by other it'll be recreated
      vm.add_poi(poi) if is_new_poi ||
                         (diff_added.present? && diff_added[poi.id.to_s].present? && diff_added[poi.id.to_s].include?('self')) ||
                         (diff_deleted.present? && diff_deleted[poi.id.to_s].present? && diff_deleted[poi.id.to_s].include?('self'))
      note_json_list_for_user = [] # added to upload-message for user
      modified_note_data['added_note_ids'].each do |local_time_secs|
        poi_note = PoiNote.where(local_time_secs: local_time_secs).first
        vm.add_poi_note poi, poi_note
        note_json_list_for_user << poi_note_json(poi_note, false).
                                   merge({local_time_secs: poi_note.local_time_secs})
      end

      modified_note_data['deleted_note_ids'].each do |poi_note_id|
        vm.delete_poi_note poi.id, poi_note_id
      end
      
      poi_json = poi_json(poi).merge({user: { id: @user.id }})
      poi_json_for_user = poi_json.
                          merge(is_new_poi ? {local_time_secs: poi.local_time_secs} : {})
      poi_json_for_user.merge!({notes: note_json_list_for_user})
      @poi_jsons_for_user << poi_json_for_user

      # others will just be notified that poi changed and the should pull request if lat/lng is in their range
      @poi_jsons_for_others << { poi_id: poi.id, lat: poi.location.latitude.to_f, lng: poi.location.longitude.to_f }
    end

    vm.merge true, true
    cur_commit = vm.cur_commit
    commit.update_attributes hash_id: cur_commit#, timestamp: DateTime.now
    @user.snapshot.update_attribute :cur_commit, commit

    system_msg_for_user = { type: 'callback',
                            channel: 'pois',
                            action: 'poi_sync',
                            commit_hash: commit.hash_id,
                            pois: @poi_jsons_for_user }
    upload_msg_for_others = { type: 'pull_request',
                              commit_hash: commit.hash_id,
                              push_user_id: @user.id,
                              pois: @poi_jsons_for_others }

    msgs_data = [
                  { channel: "/system#{PEER_CHANNEL_PREFIX}#{@user.comm_port.sys_channel_enc_key}",
                    msg: system_msg_for_user,
                    user_id: @user.id },
                 #{ channel: "/pois#{PEER_CHANNEL_PREFIX}#{@user.comm_port.channel_enc_key}",
                  { channel: "/system",
                    msg: upload_msg_for_others,
                    user_id: @user.id }
                ]
    Publisher.new.publish msgs_data, fork_publish
  end

  def self.delete_poi user_id, poi_id
    PostCommit.new.delete_poi user_id, poi_id
  end

  def delete_poi user_id, poi_id, fork_publish = true
    LOGGER.debug "delete_poi: user_id = #{user_id}, poi_id = #{poi_id}"
    @user = User.find user_id

    vm = VersionManager.new Poi::MASTER, Poi::WORK_DIR_ROOT, @user, false#@user.is_admin?
    prev_commit = vm.cur_commit
    
    vm.delete_poi poi_id

    vm.merge true, true
    cur_commit = vm.cur_commit
   
    system_msg_for_user = { type: 'callback',
                            channel: 'pois',
                            action: 'poi_delete',
                            commit_hash: cur_commit,
                            poi_id: poi_id }
    upload_msg_for_others = { type: 'poi_delete',
                              commit_hash: cur_commit,
                              push_user_id: @user.id,
                              poi_id: poi_id }

   msgs_data = [
                  { channel: "/system#{PEER_CHANNEL_PREFIX}#{@user.comm_port.sys_channel_enc_key}",
                    msg: system_msg_for_user,
                    user_id: @user.id },
                 #{ channel: "/pois#{PEER_CHANNEL_PREFIX}#{@user.comm_port.channel_enc_key}",
                  { channel: "/system",
                    msg: upload_msg_for_others,
                    user_id: @user.id }
                ]
    Publisher.new.publish msgs_data, fork_publish
  end

end
