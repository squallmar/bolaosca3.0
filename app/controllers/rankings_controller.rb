# app/controllers/rankings_controller.rb
class RankingsController < ApplicationController
  def index
    @rankings = User.left_joins(:bets)
                    .select('users.*,
                            COALESCE(SUM(bets.points), 0) as total_points,
                            COUNT(bets.id) as bets_count,
                            SUM(CASE WHEN bets.points > 0 THEN 1 ELSE 0 END) as correct_bets_count,
                            SUM(CASE WHEN bets.guess_a = matches.score_a AND bets.guess_b = matches.score_b THEN 1 ELSE 0 END) as exact_score_count')
                    .joins('LEFT JOIN matches ON bets.match_id = matches.id AND matches.status = 2') # finalizado
                    .where('bets.status = 1 OR bets.id IS NULL') # confirmed
                    .group('users.id')
                    .order('total_points DESC')
  end
end