module Truthifi
  class ConnectionsController < ApplicationController
    REDIRECT_URI = -> { ENV.fetch("TRUTHIFI_REDIRECT_URI", "http://localhost:3001/truthifi/callback") }

    # GET /truthifi/connect — registers client (once) and redirects to Truthifi OAuth consent
    def new
      client_id = existing_client_id || TruthifiOauth.register_client(redirect_uri: REDIRECT_URI.call)

      verifier   = TruthifiOauth.generate_code_verifier
      challenge  = TruthifiOauth.derive_code_challenge(verifier)
      state      = SecureRandom.hex(16)

      session[:truthifi_code_verifier] = verifier
      session[:truthifi_state]         = state
      session[:truthifi_client_id]     = client_id

      redirect_to TruthifiOauth.authorization_url(
        client_id:      client_id,
        redirect_uri:   REDIRECT_URI.call,
        code_challenge: challenge,
        state:          state
      ), allow_other_host: true
    rescue => e
      redirect_to dashboard_path, alert: "Truthifi connect failed: #{e.message}"
    end

    # GET /truthifi/callback — exchanges code for tokens and saves connection
    def callback
      unless params[:state] == session[:truthifi_state]
        return redirect_to dashboard_path, alert: "OAuth state mismatch — please try connecting again."
      end

      if params[:error].present?
        return redirect_to dashboard_path, alert: "Truthifi authorization denied: #{params[:error_description] || params[:error]}"
      end

      client_id = session.delete(:truthifi_client_id)
      verifier  = session.delete(:truthifi_code_verifier)
      session.delete(:truthifi_state)

      tokens = TruthifiOauth.exchange_code(
        client_id:     client_id,
        code:          params[:code],
        code_verifier: verifier,
        redirect_uri:  REDIRECT_URI.call
      )

      TruthifiConnection.create!(
        client_id:        client_id,
        access_token:     tokens[:access_token],
        refresh_token:    tokens[:refresh_token],
        token_expires_at: tokens[:expires_in].present? ? tokens[:expires_in].to_i.seconds.from_now : nil,
        redirect_uri:     REDIRECT_URI.call
      )

      redirect_to dashboard_path, notice: "Truthifi connected! Syncing your accounts now…"
      TruthifiSyncJob.perform_later
    rescue => e
      redirect_to dashboard_path, alert: "Truthifi callback failed: #{e.message}"
    end

    # DELETE /truthifi/disconnect
    def destroy
      conn = TruthifiConnection.current
      if conn
        TruthifiOauth.revoke(client_id: conn.client_id, token: conn.access_token) rescue nil
        conn.destroy
      end
      redirect_to dashboard_path, notice: "Truthifi disconnected."
    end

    private

    def existing_client_id
      TruthifiConnection.current&.client_id
    end
  end
end
