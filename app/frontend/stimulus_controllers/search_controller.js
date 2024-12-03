import { Controller } from "@hotwired/stimulus"
import { debounce } from 'throttle-debounce';

export default class extends Controller {
  static targets = [
    "input",
    "inputWrap",
    "results"
  ]

  initialize() {
    this.debouncedSubmit = debounce(400, () => this.element.requestSubmit()).bind(this)
  }

  submit() {
    this.toggleSpinner(true)
    this.debouncedSubmit()
  }

  toggleSpinner(show) {
    this.inputWrapTarget.classList.toggle("fr-icon-refresh-line", show)
  }

  hideSpinner() {
    this.toggleSpinner(false)
    this.hasResultsTarget && this.resultsTarget.classList.toggle("hide", false)
  }

  hideResults() {
    this.hasResultsTarget && this.resultsTarget.classList.toggle("hide", true)
  }
}
