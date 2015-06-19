require 'spec_helper'

feature "edit event presale", js: true do

  context 'event without presale and event date more than two hours in the future' do
    let (:user) {FactoryGirl.create(:user)}

    scenario 'artist enables presale', js: true, vcr: true do
      @user = user
      sign_in @user.email, @user.password
      visit root_path
      expect(page).to have_selector '#map'
      test_out_match = page.body.match /<div id="test_out">.*<\/div>/m
      expect(test_out_match).to be_present
      test_out = test_out_match[0]
      #puts "test_out = #{test_out}"
      expect(test_out).to match /<m>Comm[^<]*<\/m>/m
      expect(test_out).to match /<m>FayeClientMock[^<]*<\/m>/m
      expect(test_out).to match /<m>MockInit-drawTile:[^<]*<\/m>/m
      expect(test_out).to match /<m>APP._initState = 3<\/m>/m
    end
  end

end
