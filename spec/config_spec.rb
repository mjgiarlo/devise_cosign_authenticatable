require 'spec_helper'

module Devise
  def self.reset_cosign_client!
    @@cosign_client = nil
  end
end

describe Devise do
  before do
    Devise.cosign_base_url = "http://www.example.com/cosign_server"
  end
  
  after { Devise.reset_cosign_client! }
  
  it "should figure out the base URL correctly" do
    Devise.cosign_client.cosign_base_url.should == "http://www.example.com/cosign_server"
  end
  
  it 'should accept extra options for the CoSign client object' do
    Devise.cosign_client_config_options = { :encode_extra_attributes_as => :json }

    conf_options = Devise.cosign_client.instance_variable_get(:@conf_options)
    conf_options.should_not be_nil
    conf_options[:encode_extra_attributes_as].should == :json
  end
end