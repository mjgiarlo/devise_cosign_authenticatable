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
  visit cosign_login_url
  fill_in "Username", :with => username
  fill_in "Password", :with => password
  click_on "Login"
  current_url.should == root_url
end