class ChatMessageDelivery < ActiveRecord::Base
  belongs_to :subscriber, class_name: 'User'
  belongs_to :last_message, class_name: 'ChatMessage'
end
