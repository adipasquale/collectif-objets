import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
    const anchor = window.location.hash?.replace("#", "")
    if (!anchor) return

    // TODO: replace with proper wait on DSFR JS init
    setTimeout(() => {
      this.element.querySelector(`button.fr-accordion__btn[aria-controls="${anchor}"]`)?.dispatchEvent(new Event('click'));
    }, 500)
  }
}
