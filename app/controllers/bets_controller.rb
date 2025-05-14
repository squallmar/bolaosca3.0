class BetsController < ApplicationController
  before_action :authenticate_user!
  
  def new
    @match = Match.find(params[:match_id])
    @bet = @match.bets.build(user: current_user)
  end

  def create
    @match = Match.find(params[:match_id])
    @bet = @match.bets.new(bet_params)
    @bet.user = current_user

    if @bet.save
      redirect_to matches_path, notice: 'Palpite criado com sucesso!'
    else
      render :new
    end
  end

  def update
    @bet = current_user.bets.find(params[:id])
    
    if @bet.update(bet_params)
      redirect_to matches_path, notice: 'Palpite atualizado com sucesso!'
    else
      render :edit
    end
  end

  private

  def bet_params
    params.require(:bet).permit(:guess_a, :guess_b)
  end
end