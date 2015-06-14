<% if (!resource.errors.empty?) -%>
$("#sign_in_flash").html("<ul><%= escape_javascript(resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe) -%></ul>")
<% elsif devise_mapping.confirmable? && (!resource.confirmed?) -%>
$("#sign_in_flash").html("<%= t('auth.email_confirm_required', email: resource.unconfirmed_email).gsub(/"/, '\\"').html_safe -%>")
<% end -%>
GUI.showLoginDialog()
