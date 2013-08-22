require 'spec_helper'

describe Devise::Strategies::CosignAuthenticatable, :type => "acceptance" do
  include RSpec::Rails::RequestExampleGroup
  include Capybara::DSL
  
  before do    
    Devise.cosign_base_url = "http://www.example.com/cosign_server"
    TestAdapter.reset_valid_users!

    User.delete_all
    User.create! do |u|
      u.username = "joeuser"
    end
  end
  
  after do
    visit destroy_user_session_url
  end
  
  def cosign_login_url
    @cosign_login_url ||= begin
      uri = URI.parse(Devise.cosign_base_url + "/login")
      uri.query = Rack::Utils.build_nested_query(:service => user_service_url)
      uri.to_s
    end
  end
  
  def cosign_logout_url
    @cosign_logout_url ||= Devise.cosign_base_url + "/logout"
  end
  
  def sign_into_cosign(username, password)
    visit root_url
    current_url.should == cosign_login_url
    fill_in "Username", :with => username
    fill_in "Password", :with => password
    click_on "Login"
  end
  
  describe "GET /protected/resource" do
    before { get '/' }

    it 'should redirect to sign-in' do
      response.should be_redirect
      response.should redirect_to(new_user_session_url)
    end
  end
  
  describe "GET /users/sign_in" do
    before { get new_user_session_url }
    
    it 'should redirect to CoSign server' do
      response.should be_redirect
      response.should redirect_to(cosign_login_url)
    end
  end
  
  it "should sign in with valid user" do
    sign_into_cosign "joeuser", "joepassword"
    current_url.should == root_url
  end
  
  it "should fail to sign in with an invalid user" do
    sign_into_cosign "invaliduser", "invalidpassword"
    current_url.should_not == root_url
  end

  describe "with a deactivated user" do
    before do 
      @user = User.first
      @user.deactivated = true
      @user.save!
    end

    it "should fail to sign in" do
      sign_into_cosign "joeuser", "joepassword"
      current_url.should == new_user_session_url
    end
  end
  
  it "should register new CoSign users if set up to do so" do
    User.count.should == 1
    TestAdapter.register_valid_user("newuser", "newpassword")
    Devise.cosign_create_user = true
    sign_into_cosign "newuser", "newpassword"
    
    current_url.should == root_url
    User.count.should == 2
    User.find_by_username("newuser").should_not be_nil
  end

  it "should register new CoSign users if we're overriding the cosign_create_user? method" do
    begin
      class << User
        def cosign_create_user?
          true
        end
      end

      User.count.should == 1
      TestAdapter.register_valid_user("newuser", "newpassword")
      Devise.cosign_create_user = false
      sign_into_cosign "newuser", "newpassword"
      
      current_url.should == root_url
      User.count.should == 2
      User.find_by_username("newuser").should_not be_nil
    ensure
      class << User
        remove_method :cosign_create_user?
      end
    end
  end
  
  it "should fail CoSign login if user is unregistered and cosign_create_user is false" do
    User.count.should == 1
    TestAdapter.register_valid_user("newuser", "newpassword")
    Devise.cosign_create_user = false
    sign_into_cosign "newuser", "newpassword"
    
    current_url.should_not == root_url
    User.count.should == 1
    User.find_by_username("newuser").should be_nil

    click_on "sign in using a different account"
    click_on "here"
    current_url.should == cosign_login_url
    fill_in "Username", :with => "joeuser"
    fill_in "Password", :with => "joepassword"
    click_on "Login"
    current_url.should == root_url
  end
end
