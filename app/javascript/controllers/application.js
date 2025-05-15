// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-loading"

const application = Application.start()
application.load(definitionsFromContext(import.meta.context))

// Inicialize tooltips/popovers
import { Tooltip, Popover } from "bootstrap"

document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
  new Tooltip(el)
})

document.querySelectorAll('[data-bs-toggle="popover"]').forEach(el => {
  new Popover(el)
})