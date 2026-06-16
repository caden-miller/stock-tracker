import { Controller } from "@hotwired/stimulus"

// Wraps Plaid Link (loaded from the CDN script in banking/connections/new.html.erb).
// On success, fills the hidden form's public_token field and submits it so the
// server can exchange it for an access_token.
export default class extends Controller {
  static targets = ["publicToken", "form"]
  static values = { token: String }

  connect() {
    this.handler = window.Plaid.create({
      token: this.tokenValue,
      onSuccess: (publicToken) => {
        this.publicTokenTarget.value = publicToken
        this.formTarget.requestSubmit()
      },
    })
  }

  open() {
    this.handler.open()
  }
}
