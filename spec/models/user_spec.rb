require 'spec_helper'

RSpec.describe User, :type => :model do

  describe '#validations' do
    def user opts = {}
      FactoryGirl.build(:user, opts)
    end

    it 'default should be valid' do
      expect(user).to be_valid
    end

    it 'email should be unique' do
      user1 = user
      user1.save!
      user2 = user email: user1.email
      expect(user2).to_not be_valid
    end
  end

end
