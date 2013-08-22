devise_cosign_authenticatable [![Build Status](https://secure.travis-ci.org/nbudin/devise_cosign_authenticatable.png)](http://travis-ci.org/nbudin/devise_cosign_authenticatable)
==========================

Written by Nat Budin<br/>
Taking a lot of inspiration from [devise_ldap_authenticatable](http://github.com/cschiewek/devise_ldap_authenticatable)

devise_cosign_authenticatable is [CoSign](http://www.jasig.org/cas) single sign-on support for
[Devise](http://github.com/plataformatec/devise) applications.  It acts as a replacement for
database_authenticatable.  It builds on [rubycas-client](http://github.com/gunark/rubycas-client)
and should support just about any conformant CoSign server (although I have personally tested it
using [rubycas-server](http://github.com/gunark/rubycas-server)).

Requirements
------------

- Rails 2.3 or greater (works with 3.x versions as well)
- Devise 1.0 or greater
- rubycas-client

Installation
------------

    gem install --pre devise_cosign_authenticatable
    
and in your config/environment.rb (on Rails 2.3):

    config.gem 'devise', :version => '~> 1.0.6'
    config.gem 'devise_cosign_authenticatable'

or Gemfile (Rails 3.x):

    gem 'devise'
    gem 'devise_cosign_authenticatable'

Setup
-----

Once devise\_cosign\_authenticatable is installed, add the following to your user model:

    devise :cosign_authenticatable
    
You can also add other modules such as token_authenticatable, trackable, etc.  Please do not
add database_authenticatable as this module is intended to replace it.

You'll also need to set up the database schema for this:

    create_table :users do |t|
      t.string :username, :null => false
    end

We also recommend putting a unique index on the `username` column:

    add_index :users, :username, :unique => true

(Note: previously, devise\_cosign\_authenticatable recommended using a `t.cosign_authenticatable` method call to update the
schema.  Devise 2.0 has deprecated this type of schema building method, so we now recommend just adding the `username`
string column as above.  As of this writing, `t.cosign_authenticatable` still works, but throws a deprecation warning in
Devise 2.0.)

Finally, you'll need to add some configuration to your config/initializers/devise.rb in order
to tell your app how to talk to your CoSign server:

    Devise.setup do |config|
      ...
      config.cosign_base_url = "https://cas.myorganization.com"
      
      # you can override these if you need to, but cosign_base_url is usually enough
      # config.cosign_login_url = "https://cas.myorganization.com/login"
      # config.cosign_logout_url = "https://cas.myorganization.com/logout"
      # config.cosign_validate_url = "https://cas.myorganization.com/serviceValidate"
      
      # The CoSign specification allows for the passing of a follow URL to be displayed when
      # a user logs out on the CoSign server. RubyCoSign-Server also supports redirecting to a
      # URL via the destination param. Set either of these urls and specify either nil,
      # 'destination' or 'follow' as the logout_url_param. If the urls are blank but
      # logout_url_param is set, a default will be detected for the service.
      # config.cosign_destination_url = 'https://cas.myorganization.com'
      # config.cosign_follow_url = 'https://cas.myorganization.com'
      # config.cosign_logout_url_param = nil

      # By default, devise_cosign_authenticatable will create users.  If you would rather
      # require user records to already exist locally before they can authenticate via
      # CoSign, uncomment the following line.
      # config.cosign_create_user = false

      # If you want to use the Devise Timeoutable module with single sign out, 
      # uncommenting this will redirect timeouts to the logout url, so that the CoSign can
      # take care of signing out the other serviced applocations. Note that each
      # application manages timeouts independently, so one application timing out will 
      # kill the session on all applications serviced by the CoSign.
      # config.warden do |manager|
      #   manager.failure_app = DeviseCosignAuthenticatable::SingleSignOut::WardenFailureApp
      # end
    end

Extra attributes
----------------

If your CoSign server passes along extra attributes you'd like to save in your user records,
using the CoSign extra_attributes parameter, you can define a method in your user model called
cosign_extra_attributes= to accept these.  For example:

    class User < ActiveRecord::Base
      devise :cosign_authenticatable
      
      def cosign_extra_attributes=(extra_attributes)
        extra_attributes.each do |name, value|
          case name.to_sym
          when :fullname
            self.fullname = value
          when :email
            self.email = value
          end
        end
      end
    end

See also
--------

* [CoSign](http://www.jasig.org/cas)
* [rubycas-server](http://github.com/gunark/rubycas-server)
* [rubycas-client](http://github.com/gunark/rubycas-client)
* [Devise](http://github.com/plataformatec/devise)
* [Warden](http://github.com/hassox/warden)

TODO
----

* Test on non-ActiveRecord ORMs

License
-------

`devise_cosign_authenticatable` is released under the terms and conditions of the MIT license.  See the LICENSE file for more
information.
