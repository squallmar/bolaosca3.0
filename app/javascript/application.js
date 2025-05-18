// Turbo e Stimulus (ok com importmap)
import "@hotwired/turbo-rails"
import "controllers"

// Rails UJS
import * as Rails from '@rails/ujs';
Rails.start();

// Bootstrap e Popper
import "@popperjs/core"
import "bootstrap"
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap

// Inicializa tooltips, popovers e modais com Bootstrap
document.addEventListener('turbo:load', () => {
  // Tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.forEach(el => {
    new bootstrap.Tooltip(el)
  })

  // Popovers
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  popoverTriggerList.forEach(el => {
    new bootstrap.Popover(el)
  })

  // Modais
  const modalTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="modal"]'))
  modalTriggerList.forEach(modalTriggerEl => {
    modalTriggerEl.addEventListener('click', () => {
      const target = modalTriggerEl.getAttribute('data-bs-target')
      if (target) {
        const modal = new bootstrap.Modal(document.querySelector(target))
        modal.show()
      }
    })
  })
})
