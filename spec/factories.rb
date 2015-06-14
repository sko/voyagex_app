include ActionDispatch::TestProcess
include AuthUtils

# load in console:
# require 'factory_girl'
# FactoryGirl.load('spec/factories.rb')

SPEC_MASTER = 'spec/serializer'
WORK_DIR_ROOT = "#{Rails.root}/spec/tmp/serializer"

FactoryGirl.define do
  
  factory :user do
    sequence(:username) { |n| "user_#{n}" }
    email { "#{username}@factory.com" }
    password 'secret78'
    confirmed_at { 2.days.ago }
    #snapshot
    foto { fixture_file_upload(Rails.root.join('spec', 'support', 'images', 'foto.png'), 'image/png') }

    after(:create) do |user, evaluator|
      user.comm_port = FactoryGirl.create :comm_port, user: user
      user.snapshot = FactoryGirl.create :user_snapshot, user: user
    end

    # required because of 'inverse_of: :snapshot'
    trait :snapshot do
    end
  end
  
  factory :comm_port do
    user
    channel_enc_key {enc_key}
    sys_channel_enc_key {enc_key}
  end
  
  factory :user_snapshot do
    user
    cur_commit {get_commit}
    location {Location.first || Location.default}
  end
  
  factory :commit do
    user
  end
  
  factory :location do
  end
  
  factory :chat_message do
    sender {FactoryGirl.create(:user)}
    text 'some text'

    trait :p2p do
      p2p_receiver {FactoryGirl.create(:user)}
    end
  end
  
  factory :chat_message_delivery do
    subscriber {FactoryGirl.create(:user)}
    channel {"/talk#{PEER_CHANNEL_PREFIX}#{FactoryGirl.create(:user).comm_port.channel_enc_key}_p2p"}
    last_message {FactoryGirl.create(:chat_message)}
  end

end

def get_commit
  Commit.latest || get_admin.snapshot.cur_commit
end

def get_admin
  admin = User.where(email: ADMIN_EMAIL_ADDRESS).first
  unless admin.present?
    admin_attrs = FactoryGirl.build(:user, email: ADMIN_EMAIL_ADDRESS).attributes
    admin_attrs.delete 'id'
    admin = User.create admin_attrs
    vm = VersionManager.new SPEC_MASTER, WORK_DIR_ROOT, admin, true
    now = DateTime.now
    commit = admin.commits.build hash_id: vm.cur_commit, timestamp: now, local_time_secs: now.to_i
    admin.create_snapshot cur_commit: commit, location: Location.first||Location.default
  end
  admin
end
