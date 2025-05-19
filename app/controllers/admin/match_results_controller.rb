class Admin::MatchResultsController < Admin::BaseController
  before_action :set_match

  def edit
    # Ação para mostrar o formulário de edição
  end

  def update
    if @match.finalize!(params[:home_score], params[:away_score])
      redirect_to admin_matches_path, notice: 'Resultado lançado com sucesso!'
    else
      render :edit
    end
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end
end