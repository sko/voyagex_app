module AuthUtils
  extend ActiveSupport::Concern

#  included do
#    before_filter :store_location
#  end

#  WARDEN_SESSION_USER_KEY = 'warden.user.reed_user.key'

#  def store_location
#    # store last url - this is needed for post-login redirect to whatever the user last visited.
#    return unless request.get? 
#    if (params[:controller] != 'sessions' &&
#        params[:controller] != 'passwords' &&
#        !request.xhr?) # don't store ajax calls
#      session[:previous_url] = request.fullpath 
#    end
#  end

  def enc_key
    src = ('a'..'z').to_a + (0..9).to_a
    code_length = 8
    (0..code_length).map { src[rand(36)] }.join
  end
  
  def todo_after_sign_in_path_for resource
    path = stored_location_for(Devise::Mapping.find_scope!(resource))
    # assume that login-paths for any resources (artists or users or ...) have a /login[\?#]? - path-element
    # after successful login we don't want to see the login-screen again
    if path.present? && (!path.match(/^(https?:\/\/#{@request.env['HTTP_HOST']}|).*?\/login([\?#].*|)$/).present?)
      if path.match(/^https?:\/\/(?!#{@request.env['HTTP_HOST']})/)
        # other domain requested ...
        path = root_path
      else
        path = root_path
      end
    else
      path = nil
      if self.is_a? OmniauthCallbacksController
        after_omni_auth_path = get_after_sign_in_url
        path = after_omni_auth_path if after_omni_auth_path.present?
      end
      path = root_path unless path.present?
    end
    path
  end

  def todo_after_sign_out_path_for resource
    by_sym = resource.is_a?(Symbol)
    if by_sym || resource.is_a?(User)
      if by_sym
        path = (resource==:fan_user ? fans.root_path : artists.root_path)
      else
        path = (resource.is_fan? ? fans.root_path : artists.root_path)
      end
    else
      path = admin_root_path
    end
    path
  end

  def disconnect_from_facebook
    unless current_user.connected_with_facebook?
      redirect_to current_user.is_artist? ? artists.profile_sharing_path : fans.root_path, :alert => 'This account is not connected with facebook'
    end

    @graph = Koala::Facebook::API.new(current_user.facebook_auth_token)
    if @graph.delete_connections("me", "permissions")
      current_user.disconnect_from_facebook
    end
    redirect_to current_user.is_artist? ? artists.profile_sharing_path : fans.root_path
  end

  def disconnect_from_twitter
    unless current_user.connected_with_twitter?
      redirect_to current_user.is_artist? ? artists.profile_sharing_path : fans.root_path, :alert => 'This account is not connected with twitter'
    end

    current_user.disconnect_from_twitter
    redirect_to current_user.is_artist? ? artists.profile_sharing_path : fans.root_path
  end

  def get_after_sign_in_url
    (request.env['omniauth.params'].present? ? request.env['omniauth.params']['continue_to'] : nil) ||
    request.env['omniauth.origin']
  end

end

