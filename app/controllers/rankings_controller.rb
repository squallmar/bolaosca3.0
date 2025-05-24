# app/controllers/rankings_controller.rb
class RankingsController < ApplicationController
  def index
        # Calcula os pontos e acertos dinamicamente a partir das apostas
    @rankings = User.left_joins(:bets)
                    .select('users.*,
                            COALESCE(SUM(bets.points), 0) as total_points,
                            COUNT(bets.id) as bets_count,
                            SUM(CASE WHEN bets.points > 0 THEN 1 ELSE 0 END) as correct_bets_count')
                    .group("users.id")
                    .order(Arel.sql("total_points DESC"))
  end
end