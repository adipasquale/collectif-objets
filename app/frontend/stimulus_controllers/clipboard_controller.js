import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static value = { content: String }

  copy(e) {
    e.preventDefault()
    const content = this.contentValue;
    navigator.clipboard.writeText(content)
    this.element.classList.remove("fr-icon-todo-line")
    this.element.classList.add("fr-icon-check-line")
    window.setTimeout(() => {
      this.element.classList.remove("fr-icon-check-line")
      this.element.classList.add("fr-icon-todo-line")
    }, 1000)
    return false
  }
}
