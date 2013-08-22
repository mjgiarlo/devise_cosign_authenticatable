module DeviseCosignAuthenticatable
  module SingleSignOut

    class StoreSessionId
      def initialize(app)
        @app = app
      end

      def call(env)
        store_session_id_for_cosign_ticket(env)
        @app.call(env)
      end

      private

      def store_session_id_for_cosign_ticket(env)
        request = Rack::Request.new(env)
        session = request.session

        if session['cosign_last_valid_ticket_store']
          sid = env['rack.session.options'][:id]
          Rails.logger.info "Storing sid #{sid} for ticket #{session['cosign_last_valid_ticket']}"
          ::DeviseCosignAuthenticatable::SingleSignOut::Strategies.current_strategy.store_session_id_for_index(session['cosign_last_valid_ticket'], sid)
          session['cosign_last_valid_ticket_store'] = false
        end
      end

    end
  end
end
