module Auth
  class SessionsController < Devise::SessionsController  
    include UserHelper

    before_filter :ensure_params_exist, only: [:create]
    skip_before_action :verify_authenticity_token#, if: :sign_out_request?
    #skip_before_action :protect_from_forgery, if: :sign_out_request?
    skip_before_filter :verify_signed_out_user

    def new
      if request.xhr?
        render "devise/sessions/new", layout: false, formats: [:js], locals: { resource: User.new, resource_name: :user }
      else
        #flash[:exec] = 'show_login_dialog'
        #render "main/index"
        if devise_mapping.confirmable? && tmp_user.confirmation_token.present?
          redirect_to root_path(exec: 'show_login_dialog_confirm_email', email: tmp_user.email)
        else
          redirect_to root_path(exec: 'show_login_dialog')
        end
      end
    end

    def create
      @user = User.find_for_database_authentication(email: params[:user][:email])
      return invalid_login_attempt unless @user
      if @user.valid_password?(params[:user][:password])
        sign_in(@user)
        session.delete :tmp_user_id
        render "devise/sessions/success", layout: false, formats: [:js], locals: {resource: @user, resource_name: :user}
      else
        @user.errors.add ' ', t('devise.failure.invalid', authentication_keys: 'email')
        render "devise/sessions/new", layout: false, formats: [:js], locals: { resource: @user, resource_name: :user }
      end
    end
    
    def destroy
      @user = current_user
      sign_out @user if @user.present?
      session.delete :vx_id_provider

      render "devise/sessions/destroyed", layout: false, formats: [:js]
    end

    protected

    # @see skip_before_action
    def sign_out_request?
      action_name.to_sym == :destroy
    end
    
    def ensure_params_exist
      return unless params[:user][:email].blank? && params[:user][:password].blank?
      redirect_to new_user_session_path, message: 'params missing'
    end
 
    def invalid_login_attempt
      if request.xhr?
        unconfirmed_email_params = tmp_user.unconfirmed_email.present? ? {unconfirmed_email: tmp_user.unconfirmed_email} : {}
        user = User.new(params[:user].merge!(unconfirmed_email_params).except(:password, :password_confirmation).permit!)
        user.errors.add :email, t('auth.user_unknown') unless tmp_user.unconfirmed_email.present?
        render "devise/sessions/new", layout: false, formats: [:js], locals: { resource: user, resource_name: :user }
      else
        redirect_to new_user_session_path, message: 'invalid login attempt'
      end
    end

  end
end
