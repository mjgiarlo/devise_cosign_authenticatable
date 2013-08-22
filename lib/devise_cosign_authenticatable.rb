require 'devise'
require 'devise_cosign_authenticatable/schema'
require 'devise_cosign_authenticatable/routes'
require 'devise_cosign_authenticatable/strategy'
require 'devise_cosign_authenticatable/exceptions'
require 'devise_cosign_authenticatable/single_sign_out'
require 'devise_cosign_authenticatable/railtie' if defined?(Rails::Railtie)

# Register as a Rails engine
module DeviseCosignAuthenticatable
  class Engine < Rails::Engine
    initializer "devise_cosign_authenticatable.single_sign_on.warden_failure_app" do |app|
      # requiring this here because the parent class calls Rails.application, which
      # isn't set up until after bundler has required the modules in this engine
      require 'devise_cosign_authenticatable/single_sign_out/warden_failure_app'
    end
  end
end

module Devise
  # The base URL of the COSIGN server.  For example, http://cosign.example.com.  Specifying this
  # is mandatory.
  @@cosign_base_url = nil

  # The login URL of the COSIGN server.  If undefined, will default based on cosign_base_url.
  @@cosign_login_url = nil

  # The login URL of the COSIGN server.  If undefined, will default based on cosign_base_url.
  @@cosign_logout_url = nil

  # The login URL of the COSIGN server.  If undefined, will default based on cosign_base_url.
  @@cosign_validate_url = nil

  # The destination url for logout.
  @@cosign_destination_url = nil

  # The follow url for logout.
  @@cosign_follow_url = nil

  # Which url to send with logout, destination or follow. Can either be nil, destination or follow.
  @@cosign_logout_url_param = nil

  # Should devise_cosign_authenticatable enable single-sign-out? Requires use of a supported
  # session_store. Currently supports active_record or redis.
  # False by default.
  @@cosign_enable_single_sign_out = false

  # What strategy should single sign out use for tracking token->session ID mapping.
  # :rails_cache by default.
  @@cosign_single_sign_out_mapping_strategy = :rails_cache

  # Should devise_cosign_authenticatable attempt to create new user records for
  # unknown usernames?  True by default.
  @@cosign_create_user = true

  # The model attribute used for query conditions. Should be the same as
  # the rubycosign-server username_column. :username by default
  @@cosign_username_column = :username

  # Name of the parameter passed in the logout query
  @@cosign_destination_logout_param_name = nil

  # Additional options for COSIGN client object
  @@cosign_client_config_options = {}

  mattr_accessor :cosign_base_url, :cosign_login_url, :cosign_logout_url, :cosign_validate_url, :cosign_destination_url, :cosign_follow_url, :cosign_logout_url_param, :cosign_create_user, :cosign_destination_logout_param_name, :cosign_username_column, :cosign_enable_single_sign_out, :cosign_single_sign_out_mapping_strategy, :cosign_client_config_options

  def self.cosign_create_user?
    cosign_create_user
  end

  # Return a COSIGNClient::Client instance based on configuration parameters.
  def self.cosign_client
    @@cosign_client ||= begin
      cosign_options = {
        :cosign_destination_logout_param_name => @@cosign_destination_logout_param_name,
        :cosign_base_url => @@cosign_base_url,
        :login_url => @@cosign_login_url,
        :logout_url => @@cosign_logout_url,
        :validate_url => @@cosign_validate_url,
        :enable_single_sign_out => @@cosign_enable_single_sign_out
      }

      cosign_options.merge!(@@cosign_client_config_options) if @@cosign_client_config_options

      COSIGNClient::Client.new(cosign_options)
    end
  end

  def self.cosign_service_url(base_url, mapping)
    cosign_action_url(base_url, mapping, "service")
  end

  def self.cosign_unregistered_url(base_url, mapping)
    cosign_action_url(base_url, mapping, "unregistered")
  end

  private
  def self.cosign_action_url(base_url, mapping, action)
    u = URI.parse(base_url)
    u.query = nil
    u.path = if mapping.respond_to?(:fullpath)
      if ENV['RAILS_RELATIVE_URL_ROOT']
        ENV['RAILS_RELATIVE_URL_ROOT'] + mapping.fullpath
      else
        mapping.fullpath
      end
    else
      if ENV['RAILS_RELATIVE_URL_ROOT']
        ENV['RAILS_RELATIVE_URL_ROOT'] + mapping.raw_path
      else
        mapping.raw_path
      end
    end
    u.path << "/" unless u.path =~ /\/$/
    u.path << action
    u.to_s
  end
end

Devise.add_module(:cosign_authenticatable,
                  :strategy => true,
                  :controller => :cosign_sessions,
                  :route => :cosign_authenticatable,
                  :model => 'devise_cosign_authenticatable/model')
