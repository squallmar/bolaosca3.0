// matches_form.js

// Usamos turbo:load para compatibilidade com Turbo Drive
document.addEventListener("turbo:load", function() {
  // 1. Configuração da data mínima
  configureDateField();
  
  // 2. Configuração da validação do formulário
  setupFormValidation();
  
  // 3. Configuração dos selects de times e logos
  setupTeamSelects();
  
  // 4. Inicialização do Select2 (se disponível)
  initializeSelect2();
});

// Função para configurar o campo de data
function configureDateField() {
  const dateField = document.getElementById("match-date-field");
  if (!dateField) return;

  const now = new Date();
  const timezoneOffset = now.getTimezoneOffset() * 60000;
  const localISOTime = new Date(now - timezoneOffset).toISOString().slice(0, 16);
  
  dateField.min = localISOTime;
  
  // Só define valor padrão se não houver valor existente
  if (!dateField.value) {
    dateField.value = localISOTime;
  }
}

// Função para configurar a validação do formulário
function setupFormValidation() {
  const form = document.getElementById("match-form");
  if (!form) return;

  form.addEventListener("submit", function(event) {
    event.preventDefault();
    event.stopPropagation();
    
    if (form.checkValidity()) {
      showConfirmationModal(form);
    } else {
      form.classList.add("was-validated");
    }
  }, false);

  // Validação em tempo real
  form.querySelectorAll(".form-control").forEach(input => {
    input.addEventListener("input", function() {
      this.classList.toggle("is-valid", this.checkValidity());
      this.classList.toggle("is-invalid", !this.checkValidity());
    });
  });
}

// Função para configurar os selects de times
function setupTeamSelects() {
  const teamASelect = document.getElementById('match_team_a_id');
  const teamBSelect = document.getElementById('match_team_b_id');
  
  if (teamASelect && teamBSelect) {
    // Atualiza logos iniciais
    updateTeamLogo(teamASelect, 'team-a-logo-preview');
    updateTeamLogo(teamBSelect, 'team-b-logo-preview');
    
    // Listeners para mudanças
    teamASelect.addEventListener('change', () => {
      updateTeamLogo(teamASelect, 'team-a-logo-preview');
    });
    
    teamBSelect.addEventListener('change', () => {
      updateTeamLogo(teamBSelect, 'team-b-logo-preview');
    });
  }
}

// Função para inicializar o Select2
function initializeSelect2() {
  if (typeof $ !== 'undefined') {
    $(".select2").select2({
      placeholder: function() {
        return $(this).data('placeholder') || "Selecione...";
      },
      allowClear: true,
      width: '100%'
    });
  }
}

// Função para atualizar o logo do time
function updateTeamLogo(selectElement, previewId) {
  const preview = document.getElementById(previewId);
  if (!preview) return;

  const teamId = selectElement.value;
  
  if (teamId) {
    fetch(`/teams/${teamId}/logo_info`)
      .then(response => {
        if (!response.ok) throw new Error('Erro ao carregar logo');
        return response.json();
      })
      .then(data => {
        const logoUrl = data.logo_url || "/assets/default_team.png";
        const altText = data.team_name ? `Logo do ${data.team_name}` : "Logo do time";
        preview.innerHTML = `<img src="${logoUrl}" class="img-thumbnail" style="max-height: 100px" alt="${altText}">`;
      })
      .catch(error => {
        console.error('Erro:', error);
        preview.innerHTML = `<img src="/assets/default_team.png" class="img-thumbnail" style="max-height: 100px" alt="Logo padrão">`;
      });
  } else {
    preview.innerHTML = `<img src="/assets/default_team.png" class="img-thumbnail" style="max-height: 100px" alt="Logo padrão">`;
  }
}

// Função para mostrar o modal de confirmação
function showConfirmationModal(form) {
  const formData = new FormData(form);
  
  const championshipSelect = document.getElementById("match_championship_id");
  const teamASelect = document.getElementById("match_team_a_id");
  const teamBSelect = document.getElementById("match_team_b_id");
  
  // Obtém os textos para exibição
  const championshipText = championshipSelect?.options[championshipSelect.selectedIndex]?.text || "Não especificado";
  const teamAText = teamASelect?.options[teamASelect.selectedIndex]?.text || formData.get("match[team_a]");
  const teamBText = teamBSelect?.options[teamBSelect.selectedIndex]?.text || formData.get("match[team_b]");
  const matchDate = new Date(formData.get("match[match_date]"));
  
  // Constrói o HTML do resumo
  let summaryHTML = `
    <p><strong>Campeonato:</strong> ${championshipText}</p>
    <p><strong>Times:</strong> ${teamAText} vs ${teamBText}</p>
    <p><strong>Data:</strong> ${matchDate.toLocaleDateString()} às ${matchDate.toLocaleTimeString()}</p>
  `;
  
  const location = formData.get("match[location]");
  if (location) {
    summaryHTML += `<p><strong>Local:</strong> ${location}</p>`;
  }
  
  // Atualiza o modal e exibe
  document.getElementById("match-summary").innerHTML = summaryHTML;
  
  const modal = new bootstrap.Modal(document.getElementById("confirmationModal"));
  modal.show();
  
  // Configura o botão de confirmação
  const confirmBtn = document.getElementById("confirm-submit");
  if (confirmBtn) {
    confirmBtn.onclick = () => form.submit();
  }
}