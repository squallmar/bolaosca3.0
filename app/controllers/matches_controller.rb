class MatchesController < ApplicationController
  before_action :check_admin, except: [ :index ]
  before_action :authenticate_user!, except: [ :index ]
  before_action :set_match, only: [ :edit, :update, :destroy ]

  def index
    @matches = Match.where("match_date > ?", Time.current).order(:match_date)
  end

  def new
  @match = Match.new
  @championships = Championship.all.order(:name)
  end

  def create
    @match = Match.new(match_params)
    @championships = Championship.all.order(:name)

    if @match.save
      redirect_to matches_path, notice: "Partida criada com sucesso!"
    else
      flash.now[:alert] = "Erro ao criar partida: #{@match.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @championships = Championship.all
  end

  def update
    if @match.update(match_params)
      redirect_to matches_path, notice: "Partida atualizada com sucesso!"
    else
      @championships = Championship.all
      render :edit
    end
  end

  def destroy
    @match.destroy
    redirect_to matches_path, notice: "Partida removida com sucesso!"
  end

  private

  def check_admin
    unless current_user.admin?
      redirect_to matches_path, alert: "Acesso negado"
    end
  end

  def set_match
    @match = Match.find(params[:id])
  end

  def match_params
    params.require(:match).permit(:team_a, :team_b, :match_date, :championship_id)
  end
end
