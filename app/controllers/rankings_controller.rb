class RankingsController < ApplicationController
  def index
    @rankings = User.left_joins(:bets)
                   .select('users.*, 
                           SUM(bets.points) as total_points,
                           COUNT(bets.id) as bets_count,
                           SUM(CASE WHEN bets.points > 0 THEN 1 ELSE 0 END) as correct_bets_count')
                   .group('users.id')
                   .order('total_points DESC NULLS LAST')
  end
end