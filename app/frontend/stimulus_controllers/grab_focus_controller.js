// Code from https://boringrails.com/articles/self-destructing-stimulus-controllers/

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { selector: String }

  connect() {
    this.grabFocus()
    this.element.remove()
  }

  grabFocus() {
    if (this.hasSelectorValue) {
      document.querySelector(this.selectorValue)?.focus()
    }
  }
}
