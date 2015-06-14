class Group < ActiveRecord::Base
  belongs_to :creator, class_name: 'User' 

  has_many :users_groups, inverse_of: :group
  has_many :users, :through => :users_groups
end
