module Auth
  class RegistrationsController < Devise::RegistrationsController  

    def new
      render "devise/registrations/new", layout: false, formats: [:js], locals: {resource: User.new, resource_name: :user}
    end

    def create
      user_params = params.require(:user).permit(:email, :password, :password_confirmation)
      if session[:tmp_user_id].present?
        @user = User.where(id: session[:tmp_user_id]).first
        if @user.present?
          @user.attributes = user_params.merge(confirmation_token: nil, confirmed_at: nil)
          # email-change will trigger @user.send_confirmation_instructions
        end
      end
      @user = User.new(user_params.merge!({search_radius_meters: 1000,
                                           foto: UserHelper::fetch_random_avatar(request),
                                           snapshot: UserSnapshot.new(location: Location.default, cur_commit: Commit.latest),
                                           comm_port: CommPort.new(channel_enc_key: CommPort.enc_key, sys_channel_enc_key: CommPort.enc_key)})) unless @user.present?
      if @user.save
        # user has to confirm email-address first, so no sign_in @user
        #redirect_to root_path(exec: 'show_login_dialog_confirm_email')
        render "devise/registrations/success", layout: false, formats: [:js], locals: {resource: @user, resource_name: :user}
      else
        warden.custom_failure!
        render "devise/registrations/new", layout: false, formats: [:js], locals: {resource: @user, resource_name: :user}
      end
    end

  end
end
