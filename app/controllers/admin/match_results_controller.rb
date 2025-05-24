# app/controllers/admin/match_results_controller.rb
module Admin
  class MatchResultsController < Admin::BaseController # Herda de Admin::BaseController

    before_action :set_match, only: [:edit, :update] # Garante que @match é definido

    # GET /admin/matches/:id/result
    def edit
      # Simplesmente renderiza o formulário. @match já está disponível.
    end

    # PATCH /admin/matches/:id/result
    def update
      # Usa strong parameters para permitir apenas score_a e score_b.
      # O status da partida será atualizado para 'finalized' quando a rodada for finalizada.
      match_params = params.require(:match).permit(:score_a, :score_b)

      if @match.update(match_params)
        # Redireciona para a página da partida ou para a lista de partidas do admin
        redirect_to admin_match_path(@match), notice: 'Placar da partida salvo com sucesso.'
      else
        # Se houver erros de validação, renderiza novamente o formulário
        flash.now[:alert] = 'Erro ao salvar placar da partida: ' + @match.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    # REMOVA A AÇÃO `finalize` INTEIRA, pois ela não será mais usada no novo fluxo.
    # def finalize
    #   # ... (código antigo) ...
    # end

    private

    def set_match
      @match = Match.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_matches_path, alert: 'Partida não encontrada.'
    end
  end
end