module Auth
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController

    def self.provides_callback_for network
      class_eval %Q{
        def #{network}
          @user = User.find_for_oauth(env["omniauth.auth"], current_user)

          if @user.present? && @user.persisted?
            sign_in_and_redirect @user, event: :authentication
            session.delete :tmp_user_id
            session[:vx_id_provider] = '#{network}'
            set_flash_message(:notice, :success, kind: "#{network}".capitalize) if is_navigational_format?
          else
            session["devise.#{network}_data"] = env["omniauth.auth"]
            redirect_to new_user_registration_url
          end
        end
      }
    end

    SOCIAL_NETS_CONFIG.keys.each do |network|
      next if network.match(/_#{Rails.env}$/).present?

      provides_callback_for network
      provides_callback_for "#{network}_mobile"
    end

    # http://sourcey.com/rails-4-omniauth-using-devise-with-twitter-facebook-and-linkedin/
    # we could confirm unconfirmed social-network-email-addresses here
    def after_sign_in_path_for(resource)
  #    if resource.email_verified?
        super resource
  #    else
  #      fans.finish_signup_path(resource)
  #    end
    end

  end
end