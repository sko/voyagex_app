module ::GeoUtils
  extend ActiveSupport::Concern

  #
  def shorten_address location, lookup = false
    if location.address.present?
      parts = location.address.split(',')
      if parts.size >= 3
        parts.drop([parts.size - 2, 2].min).join(',').strip
      else
        location.address
      end
    else
      unless location.persisted?
        if lookup
          geo = Geocoder.search([location.latitude, location.longitude])
          if geo.present? && geo[0].present?
            address = geo[0].address
            parts = address.split(',')
            if parts.size >= 3
              if [:google].include? Geocoder.config[:lookup]
                return parts.reverse.drop([parts.size - 2, 2].min).join(',').strip
              else
                return parts.drop([parts.size - 2, 2].min).join(',').strip
              end
            end
          end
        end
      end
      "#{location.latitude}-#{location.longitude}"
    end
  end

  # http://www.csgnetwork.com/degreelenllavcalc.html
  def lat_lng_limits lat, lng, radius_meters
    latRAD = lat/180 * Math::PI
    m1 = 111132.92
    m2 = -559.82
    m3 = 1.175
    m4 = -0.0023
    p1 = 111412.84
    p2 = -93.5
    p3 = 0.118

    # Calculate the length of a degree of latitude and longitude in meters
    latlen = m1 + (m2 * Math.cos(2 * latRAD)) + (m3 * Math.cos(4 * latRAD)) + (m4 * Math.cos(6 * latRAD))
    longlen = (p1 * Math.cos(latRAD)) + (p2 * Math.cos(3 * latRAD)) + (p3 * Math.cos(5 * latRAD));

    meter_lat = 1.0 / latlen
    meter_lng = 1.0 / longlen

    diameter_lat = meter_lat * radius_meters
    diameter_lng = meter_lng * radius_meters
    afterCommaFactor = 10000000 # 7
    inner_square_half_side_length_lat = (Math.sqrt((2*diameter_lat)**2) / 2*afterCommaFactor).round.to_f/afterCommaFactor
    inner_square_half_side_length_lng = (Math.sqrt((2*diameter_lng)**2) / 2*afterCommaFactor).round.to_f/afterCommaFactor
    
    {:lng_west => (lng-inner_square_half_side_length_lng).to_f,
     :lng_east => (lng+inner_square_half_side_length_lng).to_f,
     :lat_south => (lat-inner_square_half_side_length_lat).to_f,
     :lat_north => (lat+inner_square_half_side_length_lat).to_f}
  end

  def limits_constraint location, radius_meters = 10, limits_lat_lng = {}
    limits = lat_lng_limits location.latitude, location.longitude, radius_meters
    limits_lat_lng[:limits_lat] = limits[:lat_south]..limits[:lat_north]
    limits_lat_lng[:limits_lng] = limits[:lng_west]..limits[:lng_east]
    limits
  end

  def within_limits lat, lng, limits
    lat >= limits[:lat_south] && lat <= limits[:lat_north] &&
    lng >= limits[:lng_west] && lng <= limits[:lng_east]
  end

  def nearby_pois location, radius_meters = 10, limits_lat_lng = {}
    limits = limits_constraint location, radius_meters, limits_lat_lng
    nearbys = Poi.joins(:location).where(locations: { latitude: limits_lat_lng[:limits_lat], longitude: limits_lat_lng[:limits_lng] })
  end

  # this will save the location or a nearby poi-location with the user
  # TODO separate saving locations_users
  def nearby_poi user, location, radius_meters = 10
    # FIXME:
    # 1) when address is available check same address
    # 2) otherwise range
   #nearbys = location.nearbys(0.01)
    limits_lat_lng = {}
    nearbys = nearby_pois location, radius_meters, limits_lat_lng
    if nearbys.present?
      # TODO check address, then get closest - not first
      user_nearbys = user.locations.where(id: nearbys.collect{|poi|poi.location.id})
      if user_nearbys.present?
        poi = nearbys.find{|poi|poi.location.id==user_nearbys[0].id}
        user_nearbys[0].touch
        location = user_nearbys[0]
      else
        poi = nearbys.first
        user.locations_users.create(location: poi.location)
        #location.reload
      end
    else
      nearbys = Location.where(locations: { latitude: limits_lat_lng[:limits_lat], longitude: limits_lat_lng[:limits_lng] })
      if nearbys.present?
        # TODO check address, then get closest - not first, check not to bookmark home_base
        user_nearbys = user.locations.where(id: nearbys.collect{|location|location.id})
        if user_nearbys.present?
          user_nearbys[0].touch 
          location = user_nearbys[0]
        else
          location = nearbys.first
          user.locations_users.create(location: location)
          #location.reload
        end
      else
        user.locations_users.create(location: location)
        #location.reload
      end
      # caller can save it if required
      poi = Poi.new location: location
    end
    poi
  end

  # this will save the location or a nearby poi-location with the user
  def nearby_location location, radius_meters = 10, limits_lat_lng = {}
    limits = limits_constraint(location, radius_meters, limits_lat_lng) unless limits_lat_lng.present?
    nearbys = Location.where(locations: { latitude: limits_lat_lng[:limits_lat], longitude: limits_lat_lng[:limits_lng] })
    nearbys.first || location
  end

end

