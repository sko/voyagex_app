module ApplicationHelper

  def comm_adapter
    #@comm_adapter ||= Object.const_get(COMM_ADAPTER_CLASS).new
    ApplicationController.comm_adapter
  end

  #
  #
  #
  def is_mobile
    #return true if true
    request.user_agent =~ /Mobile|webOS/
  end
  
  #
  #
  #
  def devise_mapping
    Devise.mappings[:user]
  end
  
  #
  #
  #
  def lang_change_links request, clear_params = []
    # I18n.locale
    # "http://localhost:3000/search/show_checks_from_now?l=en&user_id=33"
    request_uri = request.env['REQUEST_URI'].sub(/[&]?l=[^&]+([&]?)/, "\\1")
    query_off_idx = request_uri.index('?')
    if query_off_idx.nil?
      lang_change_link_before = request_uri
      lang_change_link_after = ''
    else
      clear_params.each do |c_p|
        request_uri = request_uri.sub(/[?&]?#{c_p}=[^&]*/, '')
      end
      lang_change_link_before = request_uri[0, query_off_idx]
      lang_change_link_after = "#{request_uri[query_off_idx + 1, request_uri.length]}"
    end
    [lang_change_link_before, lang_change_link_after]
  end

  #
  #
  #
  def tmp_user check_session = true
    return current_user if current_user.present?
    
    if check_session && session[:tmp_user_id].present?
      User.where(id: session[:tmp_user_id]).first || tmp_user(false)
    else
      u = User.rand_user
      u.confirm!
      session[:tmp_user_id] = u.id
      u
    end
  end

end