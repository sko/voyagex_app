<% @subscription_grant_requests.each do |peer| %>
APP.view().updateIDontFollow {id:<%=peer.id%>,username:'<%=peer.username%>',foto:{url:'<%=peer.foto.url%>'}}
<% end %>
<% @quit_subscriptions.each do |peer_port| %>
APP.view().updateIFollow {id:<%=peer_port.user.id%>,username:'<%=peer_port.user.username%>',foto:{url:'<%=peer_port.user.foto.url%>'}}
#USERS.unsubscribeFromPeerChannels {peerPort:{channel_enc_key:'<%=peer_port.channel_enc_key%>'}}
USERS.removePeer {id:<%=peer_port.user.id%>,peerPort:{channel_enc_key:'<%=peer_port.channel_enc_key%>'}}
<% end %>
<% @cancel_subscription_requests.each do |peer| %>
APP.view().updateIWantToFollow {id:<%=peer.id%>,username:'<%=peer.username%>',foto:{url:'<%=peer.foto.url%>'}}, {cancelled: true}
<% end %>
<% @subscription_granted.each do |peer| %>
APP.view().updateFollowsMe {id:<%=peer.id%>,username:'<%=peer.username%>',foto:{url:'<%=peer.foto.url%>'}}
<% end %>
<% @subscription_grant_revoked.each do |peer| %>
APP.view().removeFollowsMe {id:<%=peer.id%>,username:'<%=peer.username%>',foto:{url:'<%=peer.foto.url%>'}}
<% end %>
<% @subscription_denied.each do |peer| %>
APP.view().updateFollowsMe {id:<%=peer.id%>,username:'<%=peer.username%>',foto:{url:'<%=peer.foto.url%>'}}, {denied: true}
<% end %>
