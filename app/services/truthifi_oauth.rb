require "net/http"
require "openssl"
require "base64"
require "json"

# Handles the OAuth 2.1 + DCR (Dynamic Client Registration) flow for Truthifi.
#
# Endpoints discovered from https://api.truthifi.com/.well-known/oauth-authorization-server
module TruthifiOauth
  AUTHORIZATION_ENDPOINT = "https://app.truthifi.com/oauth/consent".freeze
  TOKEN_ENDPOINT          = "https://api.truthifi.com/oauth/token".freeze
  REGISTRATION_ENDPOINT   = "https://api.truthifi.com/oauth/register".freeze
  REVOCATION_ENDPOINT     = "https://api.truthifi.com/oauth/revoke".freeze

  # Registers this app as an OAuth client via Dynamic Client Registration (RFC 7591).
  # Returns the assigned client_id.
  def self.register_client(redirect_uri:)
    body = {
      client_name:              "Finance Monitor",
      redirect_uris:            [redirect_uri],
      token_endpoint_auth_method: "none",
      grant_types:              ["authorization_code", "refresh_token"],
      response_types:           ["code"],
      scope:                    "offline_access"
    }
    response = post_json(REGISTRATION_ENDPOINT, body)
    response["client_id"] or raise "Truthifi DCR did not return a client_id"
  end

  # Builds the authorization URL the user should be redirected to.
  def self.authorization_url(client_id:, redirect_uri:, code_challenge:, state:)
    params = {
      client_id:             client_id,
      response_type:         "code",
      redirect_uri:          redirect_uri,
      scope:                 "offline_access",
      code_challenge:        code_challenge,
      code_challenge_method: "S256",
      state:                 state
    }
    "#{AUTHORIZATION_ENDPOINT}?#{URI.encode_www_form(params)}"
  end

  # Exchanges an authorization code for access + refresh tokens.
  def self.exchange_code(client_id:, code:, code_verifier:, redirect_uri:)
    body = {
      grant_type:    "authorization_code",
      client_id:     client_id,
      code:          code,
      code_verifier: code_verifier,
      redirect_uri:  redirect_uri
    }
    parse_token_response(post_form(TOKEN_ENDPOINT, body))
  end

  # Refreshes an expired access token.
  def self.exchange_refresh_token(client_id:, refresh_token:)
    body = {
      grant_type:    "refresh_token",
      client_id:     client_id,
      refresh_token: refresh_token
    }
    parse_token_response(post_form(TOKEN_ENDPOINT, body))
  end

  # Revokes a token.
  def self.revoke(client_id:, token:)
    body = { client_id: client_id, token: token }
    post_form(REVOCATION_ENDPOINT, body)
  end

  # Generates a cryptographically random PKCE code_verifier.
  def self.generate_code_verifier
    SecureRandom.urlsafe_base64(48)
  end

  # Derives the S256 code_challenge from a code_verifier.
  def self.derive_code_challenge(verifier)
    digest = OpenSSL::Digest::SHA256.digest(verifier)
    Base64.urlsafe_encode64(digest, padding: false)
  end

  private

  def self.post_json(url, body)
    uri      = URI.parse(url)
    http     = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    request  = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
    request.body = body.to_json
    response = http.request(request)
    raise "Truthifi OAuth error (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def self.post_form(url, body)
    uri      = URI.parse(url)
    http     = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    request  = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/x-www-form-urlencoded")
    request.body = URI.encode_www_form(body)
    response = http.request(request)
    raise "Truthifi token error (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def self.parse_token_response(data)
    {
      access_token:  data["access_token"],
      refresh_token: data["refresh_token"],
      expires_in:    data["expires_in"]
    }
  end
end
