import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.observer = new MutationObserver(
      (mutationList, _observer) => {
        if (!mutationList.some(mutation => mutation.addedNodes)) return
        this.scrollToBottom()
      }
    ).observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
    this.observer = null
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
