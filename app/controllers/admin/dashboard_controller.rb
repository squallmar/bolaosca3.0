# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :check_admin

  def index
  @stats = {
    total_users: User.count,
    active_users: User.where("last_sign_in_at >= ?", 1.week.ago).count,
    upcoming_matches: Match.upcoming.count,
    pending_bets: Bet.pending.count,
    total_teams: Team.count
  }

  @recent_users = User.order(created_at: :desc).limit(5)
  @recent_matches = Match.upcoming.order(match_date: :asc).limit(5).includes(:championship)
  
 
  @pagy, @recent_teams = pagy(Team.order(created_at: :desc), items: 12)
end

  private

  def check_admin
    redirect_to root_path, alert: "Acesso não autorizado" unless current_user.admin?
  end
end
