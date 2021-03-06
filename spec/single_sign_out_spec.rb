require 'spec_helper'

describe DeviseCosignAuthenticatable::SingleSignOut::WardenFailureApp do
  include RSpec::Rails::RequestExampleGroup
  include Capybara::DSL

  describe "A logged in user with a timed out session" do

    before do      
      Devise.cosign_base_url = "http://www.example.com/cosign_server"
      User.delete_all
      @user = User.create!(:username => "joeuser")
    end

    describe "using the default warden failure app" do

      before do
        sign_into_cosign "joeuser", "joepassword"
      end

      it "redirects to cosign_login_url when warden is thrown" do
        Devise::FailureApp.any_instance.expects(:redirect_url).returns(cosign_login_url)
        Timecop.travel(Devise.timeout_in) do
          visit root_url
        end
        current_url.should == root_url
      end

    end

    describe "using the custom WardenFailureApp" do

      before do

        Devise.warden_config[:failure_app] = DeviseCosignAuthenticatable::SingleSignOut::WardenFailureApp
        sign_into_cosign "joeuser", "joepassword"
      end

      it "uses the redirect_url from the custom failure class" do
        DeviseCosignAuthenticatable::SingleSignOut::WardenFailureApp.any_instance.expects(:redirect_url).returns(destroy_user_session_url)
        Timecop.travel(Devise.timeout_in) do
          visit root_url
        end
        current_url.should match(/#{cosign_logout_url}/)
      end

    end

  end

end
