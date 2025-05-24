class Admin::MatchResultsController < Admin::BaseController
  before_action :set_match

  def edit
    
  end

  def update
    if @match.finalize!(params[:home_score].to_i, params[:away_score].to_i)
      redirect_to admin_matches_path, notice: "Resultado lançado com sucesso!"
    else
      render :edit
    end
  end

  def finalize
    if @match.update(status: :finalizado, finalized_at: Time.current)
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