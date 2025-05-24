class BetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_match, only: [ :new, :create ]
  before_action :set_bet, only: [ :edit, :update ]
  before_action :check_user_palpite_count, only: [ :create, :update ]

  def new
    @bet = @match.bets.build(user: current_user)
  end

  def create
    @bet = @match.bets.new(bet_params)
    @bet.user = current_user

    if @bet.save
      redirect_to matches_path, notice: "Palpite criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @match = @bet.match
  end

  def update
    @match = @bet.match
    if @bet.update(bet_params)
      redirect_to matches_path, notice: "Palpite atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_match
    @match = Match.find(params[:match_id])
  end

  def set_bet
    @bet = current_user.bets.find_by(id: params[:id])
    unless @bet
      redirect_to matches_path, alert: "Palpite não encontrado ou não autorizado."
    end
  end

  def bet_params
    params.require(:bet).permit(:guess_a, :guess_b)
  end

  def check_user_palpite_count
    championship_id = @bet&.match&.championship_id || @match&.championship_id
    return unless championship_id

    if current_user.bets.joins(:match).where(matches: { championship_id: championship_id }).count >= 15
      flash[:alert] = "Você já deu o número máximo de 15 palpites para este campeonato."
      redirect_to matches_path
    end
  end
end
