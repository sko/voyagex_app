<% if edit %>
  $('#whoami_form').show()
  $('#whoami_edit').hide()
  $('#whoami_nedit').hide()
<% else %>
  curU = APP.user()
  curU.username = '<%= tmp_user().username -%>'
  APP.storage().saveCurrentUser curU
  $('.whoami').each () ->
      $(this).html("<%= t('auth.whoami', username: tmp_user().username) -%>")
  $('#whoami_form').hide()
  $('#whoami_edit').show()
  $('#whoami_nedit').hide()
  $('#whoami_img_edit').show()
  $('#whoami_img_nedit').hide()
<% end %>


