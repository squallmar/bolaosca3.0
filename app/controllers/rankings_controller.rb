class RankingsController < ApplicationController
  def index
    @users = User.left_joins(:bets)
                 .group("users.id")
                 .order("SUM(bets.points) DESC")
                 .select("users.*, SUM(bets.points) as total_points")
  end
end
