class BetsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_user_palpite_count, only: [ :create, :update ] # Verifica se o usuário já deu 10 palpites para o campeonato atual

  def new
    @match = Match.find(params[:match_id])
    @bet = @match.bets.build(user: current_user)
  end

  def create
    @match = Match.find(params[:match_id])
    @bet = @match.bets.new(bet_params)
    @bet.user = current_user

    if @bet.save
      redirect_to matches_path, notice: "Palpite criado com sucesso!"
    else
      render :new
    end
  end

  def update
    @bet = current_user.bets.find(params[:id])

    if @bet.update(bet_params)
      redirect_to matches_path, notice: "Palpite atualizado com sucesso!"
    else
      render :edit
    end
  end

  private

  def bet_params
    params.require(:bet).permit(:guess_a, :guess_b)
  end

  def check_user_palpite_count
    # Supondo que você queira que o usuário tenha 10 palpites para o *campeonato atual*
    # Você precisa ter acesso ao championship_id.  A maneira de obter isso depende da sua lógica.
    # Vou assumir que você tem um método current_championship ou que o championship_id
    # está disponível nos params.  Adapte isso ao seu código.

    championship_id = params[:championship_id] || current_championship&.id

    if current_user.bets.where(match: Match.where(championship_id: championship_id)).count >= 10
      flash.alert = "Você já deu o número máximo de 10 palpites para este campeonato."
      redirect_to matches_path # Ou onde for apropriado na sua aplicação
    end
  end
end
