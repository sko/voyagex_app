#<%= window_prefix -%>$('.whoami-img').attr('src', '<%=current_user.foto.url-%>')
curU = <%= window_prefix -%>APP.user()
#userPhotoUrl = <%= window_prefix -%>Storage.Model._viewUserFoto curU
curU.foto.url = '<%=current_user.foto.url-%>'
userPhotoUrl = <%= window_prefix -%>Storage.Model.userPhotoUrl curU
if (typeof userPhotoUrl == 'string') 
  curU.foto.url = userPhotoUrl
  #<%= window_prefix -%>APP.storage().saveUser { id: curU.id, username: curU.username }, { foto: curU.foto }
  <%= window_prefix -%>USERS.refreshUserPhoto curU, null, (user, flags) ->
      <%= window_prefix -%>APP.storage().saveCurrentUser user
  <%= window_prefix -%>$('.whoami-img').attr('src', userPhotoUrl)
else if (typeof userPhotoUrl.then == 'function')
  # Assume we are dealing with a promise.
  userPhotoUrl.then (url) ->
      curU = <%= window_prefix -%>APP.user()
      curU.foto.url = url
      #<%= window_prefix -%>APP.storage().saveUser { id: curU.id, username: curU.username }, { foto: curU.foto }
      <%= window_prefix -%>USERS.refreshUserPhoto curU, null, (user, flags) ->
          <%= window_prefix -%>APP.storage().saveCurrentUser user
      <%= window_prefix -%>$('.whoami-img').each () ->
          <%= window_prefix -%>$(this).attr('src', url)
<%= window_prefix -%>APP.view().toogleUserFotoUpload()
