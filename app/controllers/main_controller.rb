class MainController < ApplicationController
  include ::AuthUtils
  include ::GeoUtils

  # used from Model.js to act withLocation
  # api-call
  def location_data
    location = Location.find(params[:location_id])
    location_json = {lat: location.latitude, lng: location.longitude, address: shorten_address(location)}
    poi = Poi.where(location_id: location.id).first
    location_json[:poi_id] = poi.id if poi.present?
    render json: location_json.to_json
  end

  def index
    @initial_subscribe = true
    tmp_user.update_attribute(:foto, UserHelper::fetch_random_avatar(request)) unless tmp_user.foto.exists?
    if signed_in? # registered_user?
      unless tmp_user.snapshot.cur_commit.present?
        vm = VersionManager.new Poi::MASTER, Poi::WORK_DIR_ROOT, tmp_user, false#user.is_admin?
        cur_commit = Commit.where(hash_id: vm.cur_commit).first
        cur_commit = User.admin.commits.create(hash_id: vm.cur_commit, timestamp: DateTime.now) unless cur_commit.present?
        tmp_user.snapshot.update_attribute :cur_commit, cur_commit
      end
    end

    nearby_m = (tmp_user.search_radius_meters||20000)
    location = tmp_user.snapshot.location.present? ? tmp_user.snapshot.location : tmp_user.last_location
    if location.present?
      load_location_data location, nearby_m
    else
      @pois = []
      @uploads = []
    end
  end

  # chrome://appcache-internals/
  def manifest
    render 'voyagex.mf', layout: false, content_type: 'text/cache-manifest'
  end

  private

  def load_location_data location, nearby_m
    limits = lat_lng_limits location.latitude, location.longitude, nearby_m
    limits_lat = limits[:lat_south] > limits[:lat_north] ? limits[:lat_north]..limits[:lat_south] : limits[:lat_south]..limits[:lat_north]
    limits_lng = limits[:lng_east] > limits[:lng_west] ? limits[:lng_west]..limits[:lng_east] : limits[:lng_east]..limits[:lng_west]
    @pois = Poi.joins(:location).where(locations: {latitude: limits_lat, longitude: limits_lng})
    @uploads = Upload.joins(attached_to: { poi: :location }).where(locations: {latitude: limits_lat, longitude: limits_lng})
  end
end
