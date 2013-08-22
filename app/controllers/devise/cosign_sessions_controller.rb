class Devise::CosignSessionsController < Devise::SessionsController
  include DeviseCosignAuthenticatable::SingleSignOut::DestroySession

  unless Rails.version =~/^4/
    unloadable
  end

  skip_before_filter :verify_authenticity_token, :only => [:single_sign_out]

  def new
    unless returning_from_cosign?
      redirect_to(cosign_login_url)
    end
  end

  def service
    redirect_to after_sign_in_path_for(warden.authenticate!(:scope => resource_name))
  end

  def unregistered
  end

  def destroy
    # if :cosign_create_user is false a CoSign session might be open but not signed_in
    # in such case we destroy the session here
    if signed_in?(resource_name)
      sign_out(resource_name)
    else
      reset_session
    end

    redirect_to(logout_url)
  end

  def single_sign_out
    if ::Devise.cosign_enable_single_sign_out
      session_index = read_session_index
      if session_index
        logger.debug "Intercepted single-sign-out request for CoSign session #{session_index}."
        session_id = ::DeviseCosignAuthenticatable::SingleSignOut::Strategies.current_strategy.find_session_id_by_index(session_index)
        if session_id
          destroy_cosign_session(session_id, session_index)
        end
      else
        logger.warn "Ignoring CoSign single-sign-out request as no session index could be parsed from the parameters."
      end
    else
      logger.warn "Ignoring CoSign single-sign-out request as feature is not currently enabled."
    end

    render :nothing => true
  end

  private

  def read_session_index
    if request.headers['CONTENT_TYPE'] =~ %r{^multipart/}
      false
    elsif request.post? && params['logoutRequest'] =~
        %r{^<samlp:LogoutRequest.*?<samlp:SessionIndex>(.*)</samlp:SessionIndex>}m
      $~[1]
    else
      false
    end
  end

  def destroy_cosign_session(session_id, session_index)
    logger.debug "Destroying cosign session #{session_id} for ticket #{session_index}"
    if destroy_session_by_id(session_id)
      logger.debug "Destroyed session #{session_id} corresponding to service ticket #{session_index}."
    end

    ::DeviseCosignAuthenticatable::SingleSignOut::Strategies.current_strategy.delete_session_index(session_index)
  end

  def returning_from_cosign?
    params[:ticket] || request.referer =~ /^#{::Devise.cosign_client.cosign_base_url}/ || request.referer =~ /^#{url_for :action => "service"}/
  end

  def cosign_login_url
    ::Devise.cosign_client.add_service_to_login_url(::Devise.cosign_service_url(request.url, devise_mapping))
  end
  helper_method :cosign_login_url

  def request_url
    return @request_url if @request_url
    @request_url = request.protocol.dup
    @request_url << request.host
    @request_url << ":#{request.port.to_s}" unless request.port == 80
    @request_url
  end

  def destination_url
    return unless ::Devise.cosign_logout_url_param == 'destination'
    if !::Devise.cosign_destination_url.blank?
      url = Devise.cosign_destination_url
    else
      url = request_url.dup
      url << after_sign_out_path_for(resource_name)
    end
  end

  def follow_url
    return unless ::Devise.cosign_logout_url_param == 'follow'
    if !::Devise.cosign_follow_url.blank?
      url = Devise.cosign_follow_url
    else
      url = request_url.dup
      url << after_sign_out_path_for(resource_name)
    end
  end

  def service_url
    ::Devise.cosign_service_url(request_url.dup, devise_mapping)
  end

  def logout_url
    begin
      ::Devise.cosign_client.logout_url(destination_url, follow_url, service_url)
    rescue ArgumentError
      ::Devise.cosign_client.logout_url(destination_url, follow_url)
    end
  end
end
