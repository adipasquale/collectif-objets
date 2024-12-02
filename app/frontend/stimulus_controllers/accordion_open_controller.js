import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { selector: String }

  initialize() {
    if (!this.target) return

    setTimeout(() => {
      this.target.dispatchEvent(new Event('click'))
      // Supprime l'élément vide utilisé pour indiquer le panneau à ouvrir
      if (this.hasSelectorValue) this.element.remove()
    }, 500)
  }

  get target() {
    const selector = this.hasSelectorValue ? this.selectorValue : window.location.hash?.replace("#", "")
    if (selector) {
      return document.querySelector(`button.fr-accordion__btn[aria-controls="${selector}"]`)
    }
  }
}
