class Admin::MatchResultsController < Admin::BaseController
  before_action :set_match

  def edit
    # Mostra o formulário para lançar resultados
  end

  def update
    if @match.update(
      score_a: params[:home_score].to_i,
      score_b: params[:away_score].to_i,
      status: "finalizado",
      finalized_at: Time.current
    )
      @match.update_rankings
      redirect_to admin_matches_path, notice: "Resultado lançado com sucesso!"
    else
      render :edit
    end
  end

  def finalize
    if @match.update(status: "finalizado", finalized_at: Time.current)
      @match.update_rankings
      redirect_to admin_matches_path, notice: "Partida finalizada com sucesso!"
    else
      redirect_to result_admin_match_path(@match), alert: "Erro ao finalizar partida"
    end
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end
end
