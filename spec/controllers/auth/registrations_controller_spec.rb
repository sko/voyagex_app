require 'spec_helper'

describe Auth::RegistrationsController, type: :controller do

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#post create' do
    context "with-views" do
      render_views
  
      it 'resonses with success' do
        expect {
          xhr :post, :create, user: {email: 'userX@gmy.de', password: 'secret78', password_confirmation: 'secret78'}
          expect(response.body).to match /email-confirmation.+required before sign in.+resend confirmation instructions/
        }.to change(User, :count).by(1)
      end
    end
  end

end 
