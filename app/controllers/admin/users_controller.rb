# app/controllers/admin/users_controller.rb
class Admin::UsersController < Admin::BaseController
  def index
    @users = User.all.order(created_at: :desc).page(params[:page])
  end
end