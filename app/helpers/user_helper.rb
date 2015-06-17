require 'net/http'

module UserHelper
  include ::GeoUtils

  def last_location user
    last_loc = user.snapshot.location||nearby_location(Location.new(latitude: user.snapshot.lat, longitude: user.snapshot.lng), 10)
  end

  def user_json user
    last_loc = last_location user
    last_loc_poi = last_loc.persisted? ? Poi.where(location: last_loc).first : nearby_pois(last_loc, 10).first
    geometry = Paperclip::Geometry.from_file(user.foto) if user.foto.present?
    foto_width = geometry.present? ? geometry.width.to_i : -1
    foto_height = geometry.present? ? geometry.height.to_i : -1

    json = { id: user.id,
             username: user.username,
             lastLocation: {
               id: last_loc.id,
               lat: last_loc.latitude,
               lng: last_loc.longitude,
               address: shorten_address(last_loc, true)
             },
             foto: {
               url: user.foto.url,
               width: foto_width,
               height: foto_height
             },
             searchRadiusMeters: user.search_radius_meters||1000 }
    json[:lastLocation][:poiId] = last_loc_poi.id if last_loc_poi.present?
    
    json
  end

  def peer_json c_p, flags
    json = user_json c_p.user
    json[:flags] = flags
    if flags[:i_follow].present?
      json[:peerPort] = { channel_enc_key: c_p.channel_enc_key }
    end

    json
  end

  def users_json
    users_json = []
    peers_index = {}
    
    # i_follow
    rel = tmp_user.follows # User
    rel.each { |u| add_to_users_json(peers_index, users_json, u, { i_follow: true }) }
    # i_want_to_follow
    rel = tmp_user.requested_grant_to_follow # CommPort
    rel.each { |c_p| add_to_users_json(peers_index, users_json, c_p.user, { i_want_to_follow: true }) }
    # i_dont_follow 
    rel = User.joins(:comm_port).where('`users`.id != ? and `users`.current_sign_in_at is not null and `comm_ports`.id not in (select `comm_peers`.comm_port_id from `comm_peers` where `comm_peers`.peer_id = ?)', tmp_user.id, tmp_user.id).order('`users`.username')
    rel.each { |u| add_to_users_json(peers_index, users_json, u, { i_dont_follow: true }) }
    # follow_me
    rel = tmp_user.comm_port.followers.order(:username) # User
    rel.each { |u| add_to_users_json(peers_index, users_json, u, { follows_me: true }) }
    # want_to_follow_me
    rel = tmp_user.comm_port.follow_grant_requests.order(:username) # User
    rel.each { |u| add_to_users_json(peers_index, users_json, u, { wants_to_follow_me: true }) }

    users_json
  end

  #
  #
  #
  def self.fetch_gravatar email, request = nil
    host = 'www.gravatar.com'
    port = 80
    email_md5 = Digest::MD5.hexdigest(email)
    path = "/avatar/#{email_md5}"
    extra_response_headers = ['Content-Disposition']
    if request.present?
      request_headers = { 'Accept-Language' => request.env['HTTP_ACCEPT_LANGUAGE'],
                          'User-Agent' => request.env['HTTP_USER_AGENT'] }
      response = self.get_resource host, port, path, request_headers, extra_response_headers
      response.extra_headers[extra_response_headers[0]].match(/filename="#{email_md5}\./).present? ? response : nil
    else
      response = self.head_resource host, port, path, {}, extra_response_headers
      response.extra_headers[extra_response_headers[0]].match(/filename="#{email_md5}\./).present? ? "http#{port==443 ? 's' : ''}://#{host}:#{port}#{path}" : nil
    end
  end

  #
  #
  #
  def self.fetch_random_avatar request = nil
bu = <<bu
p00=
p01=55
p02=41
p03=
p04=
p05=46
p06=31
p07=78
p08=13
p09=
p10=
p11=91
p12=
p13=
p14=
p15=&
bu
query = <<query
mode=img&\
download=&\
avatartext=&\
fontsize=12&\
fontcolor=%23000000&\
ytext=0&\
xtext=0&\
imgformat=png
query
    #valid_p_params = [1,2,5,6,7,8,11]
    valid_p_params = [1,2,3,4,5,6,7,8,9,10,11,12,13,14]
    p_params = ""
    #(0..15).each {|i| p_params = "#{p_params}&p#{i.to_s.ljust(2,"0")}=#{rand(100)}"}
    (0..15).each {|i| p_params = "#{p_params}&p#{i.to_s.ljust(2,"0")}=#{valid_p_params.include?(i) ? rand(100) : 0}"}
    color_params = ""
    color_params = "#{color_params}&haircolor=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&skincolor=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&eyecolor=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&lipcolor=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&warecolor1=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&warecolor2=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&warecolor3=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    ordinate_params = ""
    (0..15).each {|i| ordinate_params = "#{ordinate_params}&y#{i.to_s.ljust(2,"0")}=0&x#{i.to_s.ljust(2,"0")}=0"}
    
    query_string = "#{query.lstrip.rstrip}#{p_params}#{color_params}#{ordinate_params}"
    puts "#{query_string}"
    
    target_host = "www3023ud.sakura.ne.jp"
    target_port = 80
    target_path = "/illustmaker/m.cgi?#{query_string}"

    avatar_image_url = "http#{target_port==443 ? 's' : ''}://#{target_host}:#{target_port}#{target_path}"
    request_options = {allow_redirections: :safe}
    if request.present?
      request_options.merge!({ 'Accept-Language' => request.env['HTTP_ACCEPT_LANGUAGE'],
                               'User-Agent' => request.env['HTTP_USER_AGENT'] })
    end
    begin
      return open(avatar_image_url, request_options){|t|t.base_uri}
    rescue
      Rails.logger.error "error when trying to get avatar from #{target_host}"
    end
    nil
  end

  #
  # 
  #
  def self.get url, request_headers = {}, extra_response_headers = [], redirects = []
    m = url.match(/^http(s?):\/\/([^:\/]+):?([^\/]*)(\/.*)/)
    ssl = m[1] == 's'
    get_resource m[2], m[3].present? ? m[3].to_i : (ssl ? 443 : 80), m[4], request_headers
  end

  #
  #
  #
  def self.head_resource host, port, path, request_headers = {}, extra_response_headers = []
    self.load_resource host, port, Net::HTTP::Head.new(path), request_headers, extra_response_headers
  end

  #
  #
  #
  def self.get_resource host, port, path, request_headers = {}, extra_response_headers = []
    self.load_resource host, port, Net::HTTP::Get.new(path), request_headers, extra_response_headers
  end

  #
  #
  #
  def self.load_resource host, port, request, request_headers = {}, extra_response_headers = [], redirects = []
    response_data = Struct.new(:response_code, :content_type, :extra_headers, :content, :redirects).new -1, nil, {}, nil, redirects
    request.add_field("Host", host)
    request_headers.each { |h, v| request.add_field(h.to_s, v) }
    target_conn = Net::HTTP.new(host, port)
    if port == 443
      target_conn.use_ssl = true
      target_conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    target_conn.start do |http|
      http.request(request) do |response|
        response_data.response_code = response.code
        if response.code  == '302'
          response_data.redirects.push response.header["Location"]
        else
          response_data.content_type = response.header["Content-Type"]
          extra_response_headers.each { |h| response_data.extra_headers[h] = response.header[h.to_s] }
          response_data.content = response.read_body
        end
      end
    end
    if response_data.response_code  == '302'
      return nil if redirects.size >= 3
      self.get(response_data.redirects.last, request_headers, extra_response_headers, redirects)
    else
      response_data
    end
  end

private

  def add_to_users_json peers_index, users_json, peer, flags
    idx = peers_index[peer.id]
    if idx.present?
      users_json[idx][:flags].merge! flags
    else
      peers_index[peer.id] = users_json.length
      users_json << peer_json(peer.comm_port, flags)
    end
  end

end
