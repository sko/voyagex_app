
#
# users follow themselves:
# CommPeer.joins(comm_port: :user).where('`comm_ports`.user_id = `users`.id and `comm_peers`.peer_id = `users`.id')
#
class CommPort < ActiveRecord::Base
  belongs_to :user
  has_many :comm_peers, dependent: :destroy
  has_many :peers, class_name: 'User', through: :comm_peers # peers follow user

  def followers
    peers.where(comm_peers: { granted_by_user: true })
  end

  def follow_grant_requests
    t = CommPeer.arel_table
    peers.where(t[:granted_by_user].eq(nil).or(t[:granted_by_user].eq(false)))
  end

  def self.enc_key
    src = ('a'..'z').to_a + (0..9).to_a
    code_length = 8
    (0..code_length).map { src[rand(36)] }.join
  end
end
