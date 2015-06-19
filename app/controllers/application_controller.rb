class ApplicationController < ActionController::Base

  @@comm_adapter = nil

  before_filter :set_locale, :store_location
  
  protect_from_forgery with: :null_session
#  skip_before_action :verify_authenticity_token, if: :json_request?
#  skip_before_action :protect_from_forgery
    
    
  include ApplicationHelper
  helper :all
    
  layout :mobile_by_useragent
 
  def self.comm_adapter
    Rails.logger.debug "ApplicationController - self.comm_adapter: @@comm_adapter = #{@@comm_adapter}"
    #@comm_adapter ||= Object.const_get(COMM_ADAPTER_CLASS).new
    @@comm_adapter ||= (@@comm_adapter = Object.const_get(COMM_ADAPTER_CLASS).new)
  end

  #
  #
  #
  def set_locale
    first_browser_lang = request.env['HTTP_ACCEPT_LANGUAGE'].sub(/^([a-z]{2}).*/, "\\1") unless request.env['HTTP_ACCEPT_LANGUAGE'].nil?
    I18n.locale = params[:l] || first_browser_lang || I18n.default_locale
    @url_for_extra_options = { :l => I18n.locale }
  end

  #
  #
  #
  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    if (request.fullpath != "/login" &&
        request.fullpath != "/users/sign_in" &&
        request.fullpath != "/users/sign_up" &&
        request.fullpath != "/users/password" &&
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath 
    end
  end

private

  #
  #
  #
  def mobile_by_useragent
    if is_mobile
      "application.mobile"
    else
      "application"
    end
  end

end
