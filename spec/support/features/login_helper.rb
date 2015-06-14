module Features

  module LoginHelper

    def sign_in email, password
      visit root_path
      find('#show_sign_in').click
      expect(page).to have_content("Sign In")
      fill_in 'user[email]', with: email
      fill_in 'user[password]', with: password
      #find('Sign In').click
      within('div[aria-describedby="sign_in_modal"]') do
        #find('h4', :text => 'gigflip für Fans und Konzertliebhaber').click
        find('button', :text => 'Sign In').click
      end
    end

  end

end
