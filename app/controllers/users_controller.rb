class UsersController < ApplicationController
  before_action :authenticate_user!
  
  def update
    if current_user.update(user_params)
      redirect_to profile_path, notice: 'Perfil atualizado com sucesso'
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :avatar)
  end
end