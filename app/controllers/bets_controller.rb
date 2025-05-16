class BetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_match, only: [ :new, :create ]
  before_action :set_bet, only: [ :update ]
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
    @bet = current_user.bets.find(params[:id])
    @match = @bet.match
  end

  def update
    if @bet.update(bet_params)
      redirect_to matches_path, notice: "Palpite atualizado com sucesso!"
    else
      @match = @bet.match
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_match
    @match = Match.find(params[:match_id])
  end

  def set_bet
    @bet = current_user.bets.find(params[:id])
  end

  def bet_params
    params.require(:bet).permit(:guess_a, :guess_b)
  end

  def check_user_palpite_count
    # Obtém o championship_id do match associado
    championship_id = @match&.championship_id || @bet&.match&.championship_id

    # Verifica se o usuário já fez 10 palpites para este campeonato
    if championship_id && current_user.bets.joins(:match).where(matches: { championship_id: championship_id }).count >= 10
      flash[:alert] = "Você já deu o número máximo de 10 palpites para este campeonato."
      redirect_to matches_path and return
    end
  end
end
