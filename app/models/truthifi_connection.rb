class TruthifiConnection < ApplicationRecord
  encrypts :access_token
  encrypts :refresh_token

  def self.current
    order(created_at: :desc).first
  end

  def expired?
    token_expires_at.present? && token_expires_at < 5.minutes.from_now
  end

  def refresh!
    return unless refresh_token.present?

    response = TruthifiOauth.exchange_refresh_token(
      client_id: client_id,
      refresh_token: refresh_token
    )

    if response[:access_token].blank?
      raise "Truthifi token refresh failed — no access_token returned " \
            "(refresh token may be missing or expired). Re-authorize at /truthifi/connect."
    end

    update!(
      access_token:     response[:access_token],
      refresh_token:    response[:refresh_token] || refresh_token,
      token_expires_at: response[:expires_in].present? ? response[:expires_in].to_i.seconds.from_now : nil
    )
  end
end
