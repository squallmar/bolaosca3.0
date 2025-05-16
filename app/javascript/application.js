import "@hotwired/turbo-rails"
import "controllers"

// Bootstrap e Popper
import "@popperjs/core"
import "bootstrap"
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap


// Inicializa tooltips e popovers
document.addEventListener('DOMContentLoaded', () => {
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.forEach(el => {
    new bootstrap.Tooltip(el)
  })

  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  popoverTriggerList.forEach(el => {
    new bootstrap.Popover(el)
  })
})

