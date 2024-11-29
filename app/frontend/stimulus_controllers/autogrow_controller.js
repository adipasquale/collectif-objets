// Autogrow textarea as text changes
//
// Usage <%= text_area_tag :name, content, data: { controller: "autogrow", action: "autogrow#resize" } %>

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setStyles({ resize: "none" })
    this.resize()
  }

  resize() {
    this.setStyles({ height: "auto" }) // Force textarea to shrink back to its minimum height
    this.setStyles({ height: this.scrollHeight })
  }

  get scrollHeight() {
    return Math.max(60, this.element.scrollHeight) + "px"
  }

  setStyles(styles) {
    for (var property in styles) {
      this.element.style[property] = styles[property]
    }
  }
}
