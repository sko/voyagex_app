Geocoder.configure(
  # Use FreeGeoIp as lookup provider
  #:lookup => :yandex,
  #:lookup => :freegeoip,
  :lookup => :google,

  # Default unit is kilometers
  :units => :km,

  # Cache using Redis
  :cache => Redis.new
)