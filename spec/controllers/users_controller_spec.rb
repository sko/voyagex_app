require 'spec_helper'

describe UsersController, type: :controller do

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#get unread_chat_messages' do
    render_views

    context "with-views" do
      let (:user) {FactoryGirl.create(:user)}
      let (:sender_bc_1) {FactoryGirl.create(:user)}
      let (:sender_bc_2) {FactoryGirl.create(:user)}

      it "get's unread _chat_messages" do
        c_m_1 = FactoryGirl.create(:chat_message, :p2p, p2p_receiver: user)
        user.follow! sender_bc_1
        c_m = FactoryGirl.create(:chat_message, sender: sender_bc_1)
        c_m = FactoryGirl.create(:chat_message, sender: sender_bc_1)
        user.follow! sender_bc_2
        c_m = FactoryGirl.create(:chat_message, sender: sender_bc_2)

        sign_in user
        xhr :get, :unread_chat_messages
        json = JSON.parse(response.body)
        expect(json['p2p'][c_m_1.sender.id.to_s]).to be_present
        expect(json['p2p'][c_m_1.sender.id.to_s].length).to be(1)
      end
    end
  end

end 
