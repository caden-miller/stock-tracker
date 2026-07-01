import { Controller } from "@hotwired/stimulus"

// Reloads the page every few seconds while attached. Used on the sync banner
// so the dashboard picks up freshly synced data without a manual refresh.
// Once the sync completes server-side, the banner (and this controller) no
// longer render, so the polling stops on its own.
export default class extends Controller {
  connect() {
    this.timer = setInterval(() => window.location.reload(), 4000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }
}
