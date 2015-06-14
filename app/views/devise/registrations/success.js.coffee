<% if devise_mapping.confirmable? && (!resource.confirmed?) -%>
$("#sign_in_flash").html("<%= t('auth.email_confirm_required', email: resource.unconfirmed_email).gsub(/"/, '\\"').html_safe -%>")
<% end -%>
<% if is_mobile -%>
$('#sign_up_cancel').click()
<% end -%>
GUI.showLoginDialog()
