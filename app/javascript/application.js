// Importações básicas (compartilhadas)
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap

// Funções de inicialização globais
const initializeTooltips = () => {
  const tooltips = []
  
  document.querySelectorAll('[title], [data-bs-toggle="tooltip"]').forEach(el => {
    tooltips.push(new bootstrap.Tooltip(el, {
      trigger: 'hover focus'
    }))
  })
  
  return tooltips
}

const initializeFormValidation = () => {
  document.querySelectorAll('.needs-validation').forEach(form => {
    form.addEventListener('submit', event => {
      if (!form.checkValidity()) {
        event.preventDefault()
        event.stopPropagation()
      }
      form.classList.add('was-validated')
    })
  })
}

// Event listeners globais
document.addEventListener('turbo:load', () => {
  window._tooltipInstances = initializeTooltips()
  initializeFormValidation()
})

document.addEventListener('turbo:frame-render', () => {
  initializeFormValidation()
})

document.addEventListener('turbo:before-render', () => {
  if (window._tooltipInstances) {
    window._tooltipInstances.forEach(tooltip => tooltip.dispose())
  }
})