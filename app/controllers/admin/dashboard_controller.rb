class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin

  def index
    @stats = {
      total_users: User.count,
      active_users: User.where("last_sign_in_at > ?", 1.week.ago).count,
      upcoming_matches: Match.where("match_date > ?", Time.current).count,
      pending_bets: Bet.joins(:match).where(matches: { status: :scheduled }).count
    }

    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_matches = Match.includes(:championship)
                          .where("match_date > ?", Time.current)
                          .order(match_date: :asc)
                          .limit(5)
  end

  private

  def verify_admin
    redirect_to root_path, alert: "Acesso não autorizado" unless current_user.admin?
  end
end
