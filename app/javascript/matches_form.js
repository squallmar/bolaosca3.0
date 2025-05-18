document.addEventListener("turbo:load", function () {
  configureDateField();
  setupFormValidation();
  setupTeamSelects();
  initializeSelect2();
});

function configureDateField() {
  const dateField = document.getElementById("match-date-field");
  if (!dateField) return;

  const now = new Date();
  const timezoneOffset = now.getTimezoneOffset() * 60000;
  const localISOTime = new Date(now - timezoneOffset).toISOString().slice(0, 16);

  dateField.min = localISOTime;

  if (!dateField.value) {
    dateField.value = localISOTime;
  }
}

function setupFormValidation() {
  const form = document.getElementById("match-form");
  if (!form) return;

  form.addEventListener("submit", function (event) {
    event.preventDefault();
    event.stopPropagation();

    if (form.checkValidity()) {
      showConfirmationModal(form);
    } else {
      form.classList.add("was-validated");
    }
  });

  form.querySelectorAll(".form-control, .form-select").forEach((input) => {
    input.addEventListener("input", function () {
      this.classList.toggle("is-valid", this.checkValidity());
      this.classList.toggle("is-invalid", !this.checkValidity());
    });
  });
}

function setupTeamSelects() {
  const teamASelect = document.getElementById("match_team_a_id");
  const teamBSelect = document.getElementById("match_team_b_id");

  if (teamASelect && teamBSelect) {
    updateTeamLogo(teamASelect, "team-a-logo-preview");
    updateTeamLogo(teamBSelect, "team-b-logo-preview");

    teamASelect.addEventListener("change", () =>
      updateTeamLogo(teamASelect, "team-a-logo-preview")
    );

    teamBSelect.addEventListener("change", () =>
      updateTeamLogo(teamBSelect, "team-b-logo-preview")
    );
  }
}

function initializeSelect2() {
  if (typeof $ !== "undefined" && $.fn.select2) {
    $(".select2").select2({
      placeholder: function () {
        return $(this).data("placeholder") || "Selecione...";
      },
      allowClear: true,
      width: "100%",
    });
  }
}

function updateTeamLogo(selectElement, previewId) {
  const preview = document.getElementById(previewId);
  if (!preview) return;

  const teamId = selectElement.value;

  if (teamId) {
    fetch(`/teams/${teamId}/logo_info`)
      .then((response) => {
        if (!response.ok) throw new Error("Erro ao carregar logo");
        return response.json();
      })
      .then((data) => {
        const logoUrl = data.logo_url || "/assets/default_team.png";
        const altText = data.team_name
          ? `Logo do ${data.team_name}`
          : "Logo do time";
        preview.innerHTML = `<img src="${logoUrl}" class="img-thumbnail" style="max-height: 100px" alt="${altText}">`;
      })
      .catch((error) => {
        console.error("Erro:", error);
        preview.innerHTML = `<img src="/assets/default_team.png" class="img-thumbnail" style="max-height: 100px" alt="Logo padrão">`;
      });
  } else {
    preview.innerHTML = `<img src="/assets/default_team.png" class="img-thumbnail" style="max-height: 100px" alt="Logo padrão">`;
  }
}

function showConfirmationModal(form) {
  const formData = new FormData(form);

  const championshipSelect = document.getElementById("match_championship_id");
  const teamASelect = document.getElementById("match_team_a_id");
  const teamBSelect = document.getElementById("match_team_b_id");

  const championshipText =
    championshipSelect?.selectedOptions[0]?.text || "Não especificado";
  const teamAText =
    teamASelect?.selectedOptions[0]?.text || "Time A não selecionado";
  const teamBText =
    teamBSelect?.selectedOptions[0]?.text || "Time B não selecionado";
  const matchDate = new Date(formData.get("match[match_date]"));

  let summaryHTML = `
    <p><strong>Campeonato:</strong> ${championshipText}</p>
    <p><strong>Times:</strong> ${teamAText} vs ${teamBText}</p>
    <p><strong>Data:</strong> ${matchDate.toLocaleDateString()} às ${matchDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</p>
  `;

  const location = formData.get("match[location]");
  if (location) {
    summaryHTML += `<p><strong>Local:</strong> ${location}</p>`;
  }

  document.getElementById("match-summary").innerHTML = summaryHTML;

  const modal = new bootstrap.Modal(
    document.getElementById("confirmationModal")
  );
  modal.show();

  const confirmBtn = document.getElementById("confirm-submit");
  if (confirmBtn) {
    confirmBtn.onclick = () => form.submit();
  }
}
