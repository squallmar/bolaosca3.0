// app/javascript/application.js
import "@hotwired/turbo-rails"
import "controllers"

// Importe Popper.js antes do Bootstrap
import "@popperjs/core"
import "bootstrap"

// Inicialize componentes do Bootstrap que você está usando
document.addEventListener('DOMContentLoaded', () => {
  // Tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })

  // Popovers (se estiver usando)
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
  })
})