// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"


const application = Application.start()
export default application


// Inicialize tooltips/popovers
import { Tooltip, Popover } from "bootstrap"

document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
  new Tooltip(el)
})

document.querySelectorAll('[data-bs-toggle="popover"]').forEach(el => {
  new Popover(el)
})

