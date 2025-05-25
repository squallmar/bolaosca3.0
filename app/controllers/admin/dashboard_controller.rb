# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin

  def index
    @top_scorers = User.top_scorers(5)
    @recent_teams = Team.order(created_at: :desc).page(params[:page]).per(4)
    @recent_users = User.latest(5)
    @recent_matches = Match.upcoming.with_championship(5)

    @stats = {
      total_users: User.count,
      active_users: User.active_since(1.week.ago).count,
      upcoming_matches: Match.upcoming.count,
      pending_bets: Bet.pending.count,
      total_teams: Team.count
    }
  end

  def refresh_cache
    Rails.cache.clear
    redirect_to admin_root_path, notice: 'Cache atualizado com sucesso!'
  end

  def export
    respond_to do |format|
      format.csv do
        send_data generate_export_data, filename: "dados-#{Date.today}.csv"
      end
    end
  end

  private

  def generate_export_data
    CSV.generate do |csv|
      csv << ['ID', 'Nome', 'Email'] # Cabeçalhos
      User.all.each do |user|
        csv << [user.id, user.name, user.email]
      end
    end
  end

  def check_admin
    redirect_to root_path, alert: "Acesso não autorizado" unless current_user.admin?
  end

  def user_params
    params.require(:user).permit(:email, :password, :avatar) # Adicione :avatar
  end

end
