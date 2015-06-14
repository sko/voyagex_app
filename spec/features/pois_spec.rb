require 'spec_helper'

feature "edit event presale", js: true do

  context 'event without presale and event date more than two hours in the future' do
    let (:user) {FactoryGirl.create(:user)}

    scenario 'artist enables presale', js: true, vcr: true do
      @user = user
      sign_in @user.email, @user.password
      visit root_path
      #binding.pry
      expect(page).to have_selector '#map'
      expect(page.body).to match /<div id="test_out">/
      expect(page.body).to match /<div id="test_out">.*<m>Comm[^<]*<\/m>/
      expect(page.body).to match /<div id="test_out">.*<m>FayeClientMock[^<]*<\/m>/
      expect(page.body).to match /<div id="test_out">.*<m>MockInit-drawTile:[^<]*<\/m>/
      expect(page.body).to match /<div id="test_out">BANG<\/m>/
      #expect(page.body).to match /<div id="test_out">.*;Main-_init:2/
      #find(/<div id="test_out">.*;Main-_init:2/)
      #wait_until { find("#test_out").text.should match /.*;Main-_init:2/ }
    end
  end

end
