class MatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin, except: [:index, :show]
  before_action :set_match, only: [:show, :edit, :update, :destroy]
  before_action :load_championships, only: [:new, :create, :edit, :update]

  def index
    @upcoming_matches = Match.upcoming.includes(:championship).order(match_date: :asc)
    @past_matches = Match.past.includes(:championship).order(match_date: :desc)
  end

  def show
    @bets = @match.bets.includes(:user)
  end

  def new
    @match = Match.new(match_date: Time.current.beginning_of_hour + 1.day)
  end

  def create
    @match = Match.new(match_params)
    
    if @match.save
      attach_logos
      redirect_to matches_path, notice: 'Partida criada com sucesso!'
    else
      flash.now[:alert] = "Erro ao criar partida: #{@match.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @match.update(match_params)
      attach_logos
      redirect_to @match, notice: 'Partida atualizada com sucesso!'
    else
      flash.now[:alert] = "Erro ao atualizar partida: #{@match.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @match.destroy
    redirect_to matches_path, notice: 'Partida removida com sucesso!'
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end

  def load_championships
    @championships = Championship.order(:name)
  end

  def match_params
    params.require(:match).permit(
      :championship_id,
      :team_a,
      :team_b,
      :match_date,
      :location,
      :notes,
      :team_a_logo,
      :team_b_logo
    )
  end

  def attach_logos
    @match.team_a_logo.attach(params[:match][:team_a_logo]) if params[:match][:team_a_logo]
    @match.team_b_logo.attach(params[:match][:team_b_logo]) if params[:match][:team_b_logo]
  end

  def check_admin
    unless current_user.admin?
      redirect_to matches_path, alert: 'Acesso não autorizado'
    end
  end
end