class Admin::MatchesController < Admin::BaseController
  before_action :authenticate_user!
  before_action :set_match, only: [ :show, :edit, :update, :destroy ]
  before_action :load_teams_and_championships, only: [ :new, :edit ]
  before_action :check_admin

  def index
   @matches = Match.order(created_at: :desc).page(params[:page]).per(10)
  end

  def show
  end

  def new
    @match = Match.new
    
  end

  def edit
  end

  def create
    @match = Match.new(match_params)
    if @match.save
      redirect_to admin_match_path(@match), notice: "Partida criada com sucesso."
    else
      load_teams_and_championships
      render :new
    end
  end

  def update
    if @match.update(match_params)
      redirect_to admin_match_path(@match), notice: "Partida atualizada com sucesso."
    else
      load_teams_and_championships
      render :edit
    end
  end

  def destroy
    @match.destroy
    redirect_to admin_matches_path, notice: "Partida excluída com sucesso."
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end

  def load_teams_and_championships
    @teams = Team.all
    @championships = Championship.all
  end

  def match_params
    params.require(:match).permit(
      :team_a_id,
      :team_b_id,
      :championship_id,
      :match_date,
      :score_a,
      :score_b,
      :status,
      :location,
      :notes
    )
  end

  def check_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Você não tem permissão para acessar esta página."
    end
  end
end
