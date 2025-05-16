// matches_form.js
document.addEventListener("DOMContentLoaded", function() {
  // Configuração da data mínima
  const dateField = document.getElementById("match-date-field");
  if (dateField) {
    const now = new Date();
    const timezoneOffset = now.getTimezoneOffset() * 60000;
    const localISOTime = new Date(now - timezoneOffset).toISOString().slice(0, 16);
    dateField.min = localISOTime;
    dateField.value = localISOTime; // Valor padrão
  }

  // Validação do formulário
  const form = document.getElementById("match-form");
  if (form) {
    // Validação ao tentar submeter
    form.addEventListener("submit", function(event) {
      event.preventDefault();
      event.stopPropagation();
      
      if (form.checkValidity()) {
        showConfirmationModal(form);
      } else {
        form.classList.add("was-validated");
      }
    }, false);

    // Validação em tempo real para campos inválidos
    form.querySelectorAll(".form-control").forEach(input => {
      input.addEventListener("input", function() {
        if (input.checkValidity()) {
          input.classList.remove("is-invalid");
          input.classList.add("is-valid");
        } else {
          input.classList.remove("is-valid");
        }
      });
    });
  }

  // Mostra modal de confirmação
  function showConfirmationModal(form) {
    const formData = new FormData(form);
    
    // Acessa os valores diretamente sem jQuery
    const championshipSelect = document.getElementById("match_championship_id");
    const championshipText = championshipSelect ? championshipSelect.options[championshipSelect.selectedIndex].text : "Não especificado";
    
    let summaryHTML = `
      <p><strong>Campeonato:</strong> ${championshipText}</p>
      <p><strong>Times:</strong> ${formData.get("match[team_a]")} vs ${formData.get("match[team_b]")}</p>
      <p><strong>Data:</strong> ${new Date(formData.get("match[match_date]")).toLocaleString()}</p>
    `;
    
    if (formData.get("match[location]")) {
      summaryHTML += `<p><strong>Local:</strong> ${formData.get("match[location]")}</p>`;
    }
    
    document.getElementById("match-summary").innerHTML = summaryHTML;
    
    const modal = new bootstrap.Modal(document.getElementById("confirmationModal"));
    modal.show();
    
    document.getElementById("confirm-submit").addEventListener("click", function() {
      form.submit();
    });
  }

  // Inicializa Select2 se jQuery estiver disponível
  if (typeof $ !== 'undefined') {
    $(".select2").select2({
      placeholder: "Selecione o campeonato...",
      allowClear: true
    });
  } else {
    console.warn("jQuery não está disponível. O Select2 não será inicializado.");
  }
});