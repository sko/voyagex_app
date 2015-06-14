$('#settings_form').attr('action', '<%= user_path id: current_user.id -%>')
<% if is_mobile -%>
$('#sign_in_cancel').click()
<% end -%>
<%
l_l = current_user.last_location
geometry = current_user.foto.present? ? Paperclip::Geometry.from_file(current_user.foto) : nil
foto_width = geometry.present? ? geometry.width.to_i : -1
foto_height = geometry.present? ? geometry.height.to_i : -1
%>
newU = { id: <%= current_user.id -%>,\
         username: '<%= current_user.username -%>',\
         foto: {url: '<%= current_user.foto.url -%>', width: <%= foto_width -%>, height: <%= foto_height -%>},\
         homebaseLocationId: <%= current_user.home_base.present? ? current_user.home_base.id : -1 -%>,\
         lastLocation: {lid: <%= l_l.id -%>, lat: <%= l_l.latitude -%>, lng: <%= l_l.longitude -%>, address: '<%= l_l.address -%>'},\
         searchRadiusMeters: <%= current_user.search_radius_meters||1000 %>,\
         curCommitHash: '<%= current_user.snapshot.cur_commit.hash_id -%>' }
APP.storage().saveCurrentUser newU
#USERS.refreshUserPhoto newU, null, (user, flags) ->
#    APP.storage().saveCurrentUser user
$('.whoami').each () ->
    $(this).html("<%= t('auth.whoami', username: current_user.username) -%>")
$('#whoami_edit').show()
$('#whoami_nedit').hide()
$('#whoami_img_edit').show()
$('#whoami_img_nedit').hide()
$('#sign_up_or_in').first().css('display', 'none')
$('.logout-link').each () ->
  $(this).css('display', 'block')
$('#comm_peer_data').html("<%= j render(partial: 'shared/peers', locals: {user: current_user}) -%>")
# temporary for context-nav - will be changed to template like pois_preview
$('#location_bookmarks').html("<%= j render(partial: 'main/location_bookmarks', locals: {user: current_user}) -%>")
$('#people_of_interest').html("<%= j render(partial: 'main/people_of_interest', locals: {user: current_user}) -%>")
# first unsubscripe old channels before subscribing new - TODO: check if faye handles thso orderly
for channel in VoyageX.Main.commChannels()
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+Comm.Comm.channelCallBacksJSON[channel].channel_enc_key
  Comm.Comm.unsubscribeFrom channelPath, true
Comm.Comm.resetSystemContext()
