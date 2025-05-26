// admin.js - Versão Completa
import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class AdminController extends Controller {
  connect() {
    this.initComponents()
    this.setupEventListeners()
  }

  initComponents() {
    // Tooltips
    this.initAdminTooltips()
    
    // Dropdowns
    this.initDropdowns()
    
    // Tabs
    this.initTabs()
    
    // Ripple Effect
    this.setupRippleEffect()
  }

  initAdminTooltips() {
    // Limpa tooltips existentes
    if (this.tooltips) {
      this.tooltips.forEach(tooltip => tooltip.dispose())
    }

    // Inicializa novos tooltips
    const tooltipElements = Array.from(this.element.querySelectorAll('[data-admin-tooltip]'))
    this.tooltips = tooltipElements.map(el => {
      return new bootstrap.Tooltip(el, {
        placement: 'right',
        trigger: 'hover focus'
      })
    })
  }

  initDropdowns() {
    // Dropdown do painel
    const adminDropdown = this.element.querySelector('#dashboardActions')
    if (adminDropdown) {
      this.dropdown = new bootstrap.Dropdown(adminDropdown)
    }
  }

  initTabs() {
    // Inicializa abas
    const tabEls = this.element.querySelectorAll('[data-bs-toggle="tab"]')
    tabEls.forEach(tabEl => {
      tabEl.addEventListener('click', event => {
        event.preventDefault()
        const tab = new bootstrap.Tab(event.target)
        tab.show()
      })
    })
  }

  setupRippleEffect() {
    this.element.querySelectorAll('.btn, .nav-link').forEach(link => {
      link.addEventListener('click', function(e) {
        // Não aplicar em dropdowns
        if (this.classList.contains('dropdown-toggle')) return
        
        const rect = this.getBoundingClientRect()
        const x = e.clientX - rect.left
        const y = e.clientY - rect.top
        
        const ripple = document.createElement('span')
        ripple.style.left = `${x}px`
        ripple.style.top = `${y}px`
        ripple.classList.add('ripple-effect')
        
        this.appendChild(ripple)
        
        setTimeout(() => {
          ripple.remove()
        }, 600)
      })
    })
  }

  setupEventListeners() {
    // Atualiza stats periodicamente (opcional)
    if (this.element.classList.contains('admin-dashboard')) {
      this.statsRefreshInterval = setInterval(() => {
        this.refreshStats()
      }, 300000) // 5 minutos
    }
  }

  refreshStats() {
    fetch('/admin/stats.json', {
      headers: { 'Accept': 'application/json' }
    })
    .then(response => response.json())
    .then(data => {
      this.updateStatsCards(data)
    })
  }

  updateStatsCards(data) {
    // Atualiza dinamicamente os cards de estatísticas
    document.querySelectorAll('.stats-cards [data-stat]').forEach(card => {
      const stat = card.dataset.stat
      if (data[stat]) {
        card.textContent = data[stat]
      }
    })
  }

  disconnect() {
    // Limpeza
    if (this.tooltips) this.tooltips.forEach(tooltip => tooltip.dispose())
    if (this.dropdown) this.dropdown.dispose()
    if (this.statsRefreshInterval) clearInterval(this.statsRefreshInterval)
  }
}