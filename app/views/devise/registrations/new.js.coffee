<% unless resource.errors.empty? -%>
$("#sign_up_flash").html("<ul><%= escape_javascript(resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe) -%></ul>")
<% end -%>
<% if is_mobile -%>
$(".reg-link > .ui-link").first().click()
<% else -%>
$("#sign_up_modal").dialog('open')
<% end -%>
