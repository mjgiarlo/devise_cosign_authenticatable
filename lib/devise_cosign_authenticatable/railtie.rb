require 'devise_cosign_authenticatable'
require 'rails'

module DeviseCosignAuthenticatable
  class Railtie < ::Rails::Railtie
    initializer "devise_cosign_authenticatable.use_rack_middleware" do |app|
      app.config.middleware.use "DeviseCosignAuthenticatable::SingleSignOut::StoreSessionId"
    end
  end
end
