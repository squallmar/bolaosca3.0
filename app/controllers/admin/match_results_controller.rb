class Admin::MatchResultsController < Admin::BaseController
  def edit
    @match = Match.find(params[:id])
  end

  def update
    @match = Match.find(params[:id])
    
    if @match.finalize!(params[:home_score], params[:away_score])
      redirect_to admin_matches_path, notice: 'Resultado lançado com sucesso!'
    else
      render :edit
    end
  end
end