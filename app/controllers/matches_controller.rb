class MatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin, except: [ :index, :show ]
  before_action :set_match, only: [ :show, :edit, :update, :destroy ]
  before_action :load_championships, only: [ :new, :create, :edit, :update ]
  before_action :load_teams, only: [ :new, :create, :edit, :update ]


  def index
    @upcoming_matches = Match.upcoming
      .includes(:championship, :bets, :team_a, :team_b,
                team_a_logo_attachment: :blob, team_b_logo_attachment: :blob)
      .order(match_date: :asc)

    @past_matches = Match.past
      .includes(:championship, :bets, :team_a, :team_b,
                team_a_logo_attachment: :blob, team_b_logo_attachment: :blob)
      .order(match_date: :desc)

    if user_signed_in?
      @user_bets = current_user.bets.where(match_id: (@upcoming_matches + @past_matches).pluck(:id)).index_by(&:match_id)
    end
  end

  def show
    @bets = @match.bets.includes(:user)
  end

  def new
    @match = Match.new(
      match_date: Time.current.beginning_of_hour + 1.day,
      team_a_id: Team.first&.id,
      team_b_id: Team.second&.id
    )
  end

  def create
    @match = Match.new(match_params)

    if @match.save
      attach_logos
      redirect_to matches_path, notice: "Partida criada com sucesso!"
    else
      load_teams # Recarrega os times para o formulário
      flash.now[:alert] = "Erro ao criar partida: #{@match.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @match = Match.find(params[:id])
    @match.team_a.name ||= Team.first.name
    @match.team_b.name ||= Team.second.name
    @match.match_date ||= Time.current.beginning_of_hour + 1.day
    @match.location ||= "Local da partida"

  end

  def update
    if @match.update(match_params)
      attach_logos
      redirect_to @match, notice: "Partida atualizada com sucesso!"
    else
      load_teams # Recarrega os times para o formulário
      flash.now[:alert] = "Erro ao atualizar partida: #{@match.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @match.destroy
    redirect_to matches_path, notice: "Partida removida com sucesso!"
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end

  def load_championships
    @championships = Championship.order(:name)
  end

  def load_teams
    @teams = Team.order(:name)
  end

  def match_params
    params.require(:match).permit(
      :championship_id,
      :team_a_id,
      :team_b_id,
      :match_date,
      :location,
      :notes,
      :team_a_logo,
      :team_b_logo,
      :team_a,
      :team_b
    )
  end

 def attach_logos
    # Só anexa logos se não estiver usando times do modelo Team
    unless @match.team_a || @match.team_b
      @match.team_a_logo.attach(params[:match][:team_a_logo]) if params[:match][:team_a_logo]
      @match.team_b_logo.attach(params[:match][:team_b_logo]) if params[:match][:team_b_logo]
    end
  end

  def check_admin
    redirect_to matches_path, alert: "Acesso não autorizado" unless current_user.admin?
  end
end
