class PoisController < ApplicationController 
  include ApplicationHelper
  include PoiHelper

  #
  # FIXME there's a problem with csrf from app-cache (after updating version) - 
  #       no current_user will be set then.
  #
  #skip_before_filter :verify_authenticity_token, only: [:create, :update]
  skip_before_action :verify_authenticity_token, if: :current_user_required?

  def index
    render layout: 'uploads'
  end

  def pull_pois
    @user = tmp_user

    @user.update_attributes search_radius_meters: params[:radius]
    location = nearby_location(Location.new(latitude: params[:lat], longitude: params[:lng]), 10)
    if location.persisted?
      @user.snapshot.update_attributes location: location, lat: nil, lng: nil
    else
      @user.snapshot.update_attributes location: nil, lat: location.latitude, lng: location.longitude
    end

    #if true
    if ![:development].include?(Rails.env.to_sym)
      Resque.enqueue(PostCommit, {action: 'pull_pois',
                                  user_id: @user.id,
                                  commit_hash: params[:commit_hash]})
    else
      PostCommit.new.pull_pois @user.id,
                               params[:commit_hash],
                               false
    end

    render json: { message: 'OK' }.to_json
  end

  def sync_pois
    @user = tmp_user
    now = DateTime.now
    # required for providing user to poi_notes
    commit = @user.commits.create hash_id: "#{@user.id}.#{now.to_i}", timestamp: now
    errors = []
    min_local_time_secs_list = []
    modified_poi_data = {} # commit alomne would loose info for deleted poi-notes
    params[:pois].each do |poi_id, poi_data|
      if poi_id.to_i >= 0
        # if poi is deleted by remote user when local user is offline then it will be deleted
        # on local system as soon as local user gets online - first action is pull. all eventually
        # queued poi-changes will be deleted - so it should never happen that a user calls with
        # poi-id for a non-existing poi ...
        poi = Poi.find poi_id
        if poi_data[:action] == 'delete'
          modified_poi_data[poi.id] = HashWithIndifferentAccess.new deleted: true, poi_location_latitude: poi.location.latitude.to_f, poi_location_longitude:  poi.location.longitude.to_f 
          poi.destroy
          next
        end
      else
        # poi might already exist (nearby) - so 
        poi = nearby_poi @user, Location.new(latitude: poi_data[:location][:latitude], longitude: poi_data[:location][:longitude])
        unless poi.persisted?
          poi.commit = commit
          poi.local_time_secs = poi_id.to_i.abs 
        end
        poi.location.commit = commit unless poi.location.commit.present? # location is saved in nearby_poi if it was new
      end
      @user.locations << poi.location unless @user.locations.find {|l|l.id==poi.location.id}

      modified_poi_note_data = HashWithIndifferentAccess.new added_note_ids: [], deleted_note_ids: []

      min_local_time_secs = -1
      poi_data[:notes].each do |poi_note_id, poi_note_data|
        action = poi_note_data[:action]
        if action == 'delete'
          poi_note = PoiNote.find poi_note_id.to_i.abs
          poi.notes.delete poi_note
          modified_poi_note_data[:deleted_note_ids] << poi_note_id.to_i.abs
        else
          poi_note_local_time_secs = poi_note_id.to_i.abs # (poi_note_id.to_i/1000).round.abs
          min_local_time_secs = poi_note_local_time_secs if (min_local_time_secs == -1) || (poi_note_local_time_secs < min_local_time_secs)

          file = poi_note_data[:file]
          if file.present? || (embed = poi_note_data[:embed]).present?
            upload = Upload.new(attached_to: PoiNote.new(poi: poi, commit: commit, text: poi_note_data[:text], local_time_secs: poi_note_local_time_secs))
            upload.attached_to.attachment = upload
            if file.present?
              upload.build_entity file.content_type, file: file
            else
              upload.build_entity :embed, text: embed[:content], embed_type: UploadEntity::Embed.get_embed_type(embed[:content])
            end
            poi_note = upload.attached_to
          else
            poi_note = PoiNote.new(poi: poi, commit: commit, text: poi_note_data[:text], local_time_secs: poi_note_local_time_secs)
          end
          poi.notes << poi_note
          modified_poi_note_data[:added_note_ids] << poi_note_id.to_i.abs
        end
      end
      
      if poi.save
        modified_poi_data[poi.id] = modified_poi_note_data
        min_local_time_secs_list << min_local_time_secs
      else
        errors << poi.errors.full_messages
      end
    end
    commit.update_attribute :local_time_secs, min_local_time_secs_list.min

    #if true
    if ![:development].include?(Rails.env.to_sym)
      Resque.enqueue(PostCommit, {action: 'sync_pois',
                                  commit_id: commit.id,
                                  modified_poi_data: modified_poi_data})
    else
      PostCommit.new.sync_pois commit.id,
                               modified_poi_data,
                               false
    end

    render json: { errors: errors }.to_json
  end

  # api
  def pois
    user = current_user || tmp_user

    pois_json = []
    @pois = nearby_pois Location.new(latitude: params[:lat], longitude: params[:lng]), (user.search_radius_meters||1000)
    @pois.each do |poi|
      pois_json << poi_json(poi)
    end
    
    render json: pois_json.to_json
  end

  # api
  def comments
    user = current_user || tmp_user
    if params[:poi_note_id] != '-1'
      poi_note = PoiNote.find(params[:poi_note_id])
      poi = poi_note.poi
    else
      poi_note = nil
      poi = Poi.find(params[:poi_id]) if params[:poi_id].present?
    end

    poi_json = poi_json poi
    poi_json[:notes] = poi_notes_as_list poi, poi_note

    render json: {poi: poi_json}.to_json
  end

  def csrf
    render "shared/csrf", layout: 'uploads'
  end

  protected

  # @see skip_before_action
  def current_user_required?
    [:pull_pois, :sync_pois, :destroy, :pois, :comments].include? action_name.to_sym
  end

end
