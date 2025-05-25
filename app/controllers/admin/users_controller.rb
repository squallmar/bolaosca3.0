class Admin::UsersController < Admin::BaseController
  # ... outras ações ...

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'Usuário atualizado com sucesso'
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :admin, :avatar)
  end
end