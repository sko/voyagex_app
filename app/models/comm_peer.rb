#
# follow users by subscribing to one of their comm_ports
# koeller follows schuemmer:
# schuemmer.comm_port.comm_peers.create peer: koeller, granted_by_user: true
#
class CommPeer < ActiveRecord::Base
  belongs_to :comm_port
  belongs_to :peer, class_name: 'User' # peers follow a user's comm_port
end
