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

  private

  def check_admin
    redirect_to root_path, alert: "Acesso não autorizado" unless current_user.admin?
  end
end
