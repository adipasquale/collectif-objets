// Permet de soumettre un formulaire par CTRL/META + Enter
// Implémentation : ajouter le code ci-dessous au formulaire
// data: { controller: :form, action: "keydown->form#controlSubmit" }

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  controlSubmit(e) {
    if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
      this.element.requestSubmit()
    }
  }
}
