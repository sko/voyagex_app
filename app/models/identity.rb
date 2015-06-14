class Identity < ActiveRecord::Base

  include UserHelper

  TEMP_EMAIL_PREFIX = 'verify@voyagex'
  TEMP_EMAIL_REGEX = /\Averify@voyagex/

  belongs_to :user

  def set_facebook_information auth
    self.auth_token_expires_at = Time.at(auth.credentials.expires_at)
    user.foto = open(auth.info.image.gsub("type=square", "width=1000"), :allow_redirections => :safe){|t|t.base_uri}
  end

  def set_twitter_information(auth)
    self.auth_secret = auth.credentials.secret
  end

  def update_omniauth_attributes(auth, auth_email_is_confirmed)
    has_confirmed_email = email.present? && email_is_confirmed
    if email_is_confirmed || !has_confirmed_email
      # don't overwrite confirmed email with unconfirmed email
      if auth.info.has_key?(:email)
        self.email = auth.info.email 
        self.email_is_confirmed = email_is_confirmed 
      end
    end
    self.auth_token = auth.credentials.token
    self.send "set_#{auth.provider}_information", auth
  end

  def update_omniauth_attributes!(auth, auth_email_is_confirmed)
    self.update_omniauth_attributes(auth, auth_email_is_confirmed)
    self.save
  end

  def self.find_with_omniauth auth
    return nil unless auth.present?
    where(ActionController::Parameters.new.merge!(auth.slice(:provider, :uid)).permit!).first
  end

  def self.build_with_omniauth user, auth, email = nil, email_is_confirmed = false
    Identity.new.tap do |identity|
      identity.user = user
      identity.provider = auth.provider
      identity.uid = auth.uid
      identity.email = email
      identity.email_is_confirmed = email_is_confirmed
      user.identities << identity
      unless user.persisted?
        user.username = auth.info.name.gsub(/ /, '_').camelcase
        user.email = email_is_confirmed ? email : "#{Identity::TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com"
        user.password = Devise.friendly_token[0,20]
        identity.auth_token = auth.credentials.token
        identity.send("set_#{auth.provider}_information".to_sym, auth)
        user.search_radius_meters = 1000
        user.snapshot = UserSnapshot.new(location: Location.default, cur_commit: Commit.latest)
        user.skip_confirmation!
      end
      identity
    end
  end

end
