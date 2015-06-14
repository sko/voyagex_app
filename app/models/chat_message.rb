class ChatMessage < ActiveRecord::Base
  belongs_to :sender, class_name: 'User'
  belongs_to :p2p_receiver, class_name: 'User'
end
