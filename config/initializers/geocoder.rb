Geocoder.configure(
  # Use FreeGeoIp as lookup provider
  :lookup => :yandex,

  # Default unit is kilometers
  :units => :km,

  # Cache using Redis
  :cache => Redis.new
)