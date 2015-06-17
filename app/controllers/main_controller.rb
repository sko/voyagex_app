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
    unless tmp_user.comm_port.present?
      comm_port = CommPort.create(user: tmp_user, channel_enc_key: enc_key, sys_channel_enc_key: enc_key)
    end
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
    #@uploads = Upload.all.order('location_id, id desc')
    # https://github.com/alexreisner/geocoder#request-geocoding-by-ip-address
#[1] pry(#<MainController>)> request.location
#=> #<Geocoder::Result::Freegeoip:0xf7a3c08
# @cache_hit=false,
# @data=
#  {"ip"=>"2.207.225.240",
#   "country_code"=>"DE",
#   "country_name"=>"Germany",
#   "region_code"=>"",
#   "region_name"=>"",
#   "city"=>"",
#   "zip_code"=>"",
#   "time_zone"=>"",
#   "latitude"=>51,
#   "longitude"=>9,
#   "metro_code"=>0}>
  end

  # chrome://appcache-internals/
  def manifest
    render 'voyagex.mf', layout: false, content_type: 'text/cache-manifest'
  end

  private

  def load_location_data location, nearby_m
    #@uploads = location.nearbys((nearby_km.to_f/1.609344).round).inject([]){|res,l|l.uploads.where('uploads.location_id is not null')}
    limits = lat_lng_limits location.latitude, location.longitude, nearby_m
    limits_lat = limits[:lat_south] > limits[:lat_north] ? limits[:lat_north]..limits[:lat_south] : limits[:lat_south]..limits[:lat_north]
    limits_lng = limits[:lng_east] > limits[:lng_west] ? limits[:lng_west]..limits[:lng_east] : limits[:lng_east]..limits[:lng_west]
    @pois = Poi.joins(:location).where(locations: {latitude: limits_lat, longitude: limits_lng})
    @uploads = Upload.joins(attached_to: { poi: :location }).where(locations: {latitude: limits_lat, longitude: limits_lng})
  end
end
