if defined? ActionDispatch::Routing
  # Rails 3, 4
  
  ActionDispatch::Routing::Mapper.class_eval do
    protected
  
    def devise_cosign_authenticatable(mapping, controllers)
      sign_out_via = (Devise.respond_to?(:sign_out_via) && Devise.sign_out_via) || [:get, :post]

      # service endpoint for CoSign server
      get "service", :to => "#{controllers[:cosign_sessions]}#service", :as => "service"
      post "service", :to => "#{controllers[:cosign_sessions]}#single_sign_out", :as => "single_sign_out"

      resource :session, :only => [], :controller => controllers[:cosign_sessions], :path => "" do
        get :new, :path => mapping.path_names[:sign_in], :as => "new"
        get :unregistered
        post :create, :path => mapping.path_names[:sign_in]
        match :destroy, :path => mapping.path_names[:sign_out], :as => "destroy", :via => sign_out_via
      end      
    end
  end
else
  # Rails 2
  
  ActionController::Routing::RouteSet::Mapper.class_eval do
    protected
    
    def cosign_authenticatable(routes, mapping)
      routes.with_options(:controller => 'devise/cosign_sessions', :name_prefix => nil) do |session|
        session.send(:"#{mapping.name}_service", '/service', :action => 'service', :conditions => {:method => :get})
        session.send(:"#{mapping.name}_service", '/service', :action => 'single_sign_out', :conditions => {:method => :post})
        session.send(:"unregistered_#{mapping.name}_session", '/unregistered', :action => "unregistered", :conditions => {:method => :get})
        session.send(:"new_#{mapping.name}_session", mapping.path_names[:sign_in], :action => 'new', :conditions => {:method => :get})
        session.send(:"#{mapping.name}_session", mapping.path_names[:sign_in], :action => 'create', :conditions => {:method => :post})
        session.send(:"destroy_#{mapping.name}_session", mapping.path_names[:sign_out], :action => 'destroy', :conditions => { :method => :get })
      end
    end
  end
end
