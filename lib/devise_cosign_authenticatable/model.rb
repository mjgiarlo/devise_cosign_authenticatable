module Devise
  module Models
    # Extends your User class with support for CoSign ticket authentication.
    module CosignAuthenticatable
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        # Authenticate a CoSign ticket and return the resulting user object.  Behavior is as follows:
        # 
        # * Check ticket validity using RubyCoSign::Client.  Return nil if the ticket is invalid.
        # * Find a matching user by username (will use find_for_authentication if available).
        # * If the user does not exist, but Devise.cosign_create_user is set, attempt to create the
        #   user object in the database.  If cosign_extra_attributes= is defined, this will also
        #   pass in the ticket's extra_attributes hash.
        # * Return the resulting user object.
        def authenticate_with_cosign_ticket(ticket)
          ::Devise.cosign_client.validate_service_ticket(ticket) unless ticket.has_been_validated?
          
          if ticket.is_valid?
           conditions = {::Devise.cosign_username_column => ticket.respond_to?(:user) ? ticket.user : ticket.response.user} 
            # We don't want to override Devise 1.1's find_for_authentication
            resource = if respond_to?(:find_for_authentication)
              find_for_authentication(conditions)
            else
              find(:first, :conditions => conditions)
            end
            
            resource = new(conditions) if (resource.nil? and should_create_cosign_users?)
            return nil unless resource
            
            if resource.respond_to? :cosign_extra_attributes=
              resource.cosign_extra_attributes = ticket.respond_to?(:extra_attributes) ? ticket.extra_attributes : ticket.response.extra_attributes
            end
            resource.save
            resource
          end
        end

        private
        def should_create_cosign_users?
          respond_to?(:cosign_create_user?) ? cosign_create_user? : ::Devise.cosign_create_user?
        end
      end
    end
  end
end
