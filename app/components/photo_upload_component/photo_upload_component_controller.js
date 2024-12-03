import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import Nanobar from "nanobar"
import "./photo_upload_component.css"

export default class extends Controller {
  static targets = ["input", "submit", "nanobar", "display", "group"]
  static values = { url: String, accept: String, maxFileSize: Number }

  connect() {
    this.submitTarget.remove()
    this.toggleDependentLinks(true)
  }

  disconnect() {
    this.nanobar = null
  }

  triggerUpload() {
    const files = Array.from(this.inputTarget.files)
    if (files.length !== 1) return

    this.nanobar = new Nanobar({ target: this.nanobarTarget })
    this.display(`Chargement démarré …`)
    this.toggleDependentLinks(false)
    this.uploadFile(files[0])
  }

  toggleDependentLinks(enabled) {
    document
      .querySelectorAll('[data-recensement-form-step-target="link"]')
      .forEach(link => link.toggleAttribute("disabled", !enabled))
  }

  directUploadWillStoreFileWithXHR(xhr) {
    xhr.upload.addEventListener("progress", event => this.uploadRequestDidProgress(event))
    this.display(`Chargement en cours …`)
  }

  uploadRequestDidProgress(event) {
    const progress = event.loaded / event.total * 100
    if (!progress) return

    this.display(`Chargée à ${Math.round(progress)}%`)
    this.nanobar.go(progress)
  }

  uploadFile(file) {
    // Bail out for invalid file extensions
    if (this.invalid(file)) {
      this.inputTarget.disabled = false
      this.toggleDependentLinks(true)
      return
    }
    this.inputTarget.disabled = true // so it does re-upload on form submit
    new DirectUpload(file, this.urlValue, this).create(
      (error, blob) => {
        if (error) {
          this.inputTarget.disabled = false
          this.toggleDependentLinks(true)
          this.display("Échec d'envoi du fichier", { error: true })
          console.log("ERROR on direct upload !", error)
        } else {
          const hiddenField = document.createElement("input")
          hiddenField.setAttribute("type", "hidden")
          hiddenField.setAttribute("value", blob.signed_id)
          hiddenField.name = this.inputTarget.name
          this.inputTarget.after(hiddenField)
          this.inputTarget.removeAttribute("data-uploading")
          this.display("Photo en cours d’ajout …")
          this.element.requestSubmit()
        }
      }
    )
  }

  invalid(file) {
    const extension = file.name.toLowerCase().split('.').pop()
    if (!this.acceptValue.split("|").includes(extension)) {
      this.display("Ce type de fichier n'est pas autorisé. Merci de sélectionner une photo au format jpg ou png.", { error: true })
      return true
    }
    if (this.maxFileSizeValue > 0 && file.size > this.maxFileSizeValue) {
      this.display(`Le fichier ${file.name} est trop lourd (${this.humanFileSize(file.size)}). Le poids maximum autorisé est : ${this.humanFileSize(this.maxFileSizeValue)}.`, { error: true })
      return true
    }
    return false
  }

  display(message, { error = false } = {}) {
    this.groupTarget.classList.toggle("fr-input-group--error", error)
    this.displayTarget.classList.toggle("fr-error-text", error)
    this.displayTarget.innerHTML = message || ""
  }

  humanFileSize(number) {
    if (number < 1024) {
      return `${number} octets`
    } else if (number >= 1024 && number < 1048576) {
      return `${(number / 1024).toFixed(0)} Ko`.replace(".", ",")
    } else if (number >= 1048576) {
      return `${(number / 1048576).toFixed(0)} Mo`
    }
  }
}

