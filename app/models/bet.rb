class Bet < ApplicationRecord
  belongs_to :user
  belongs_to :match

  def calculate_points
    return 0 unless match.finished?

    # Acertou o placar exato
    if guess_a == match.score_a && guess_b == match.score_b
      self.points = 10
    # Acertou o vencedor e diferença de gols
    elsif (guess_a - guess_b) == (match.score_a - match.score_b)
      self.points = 7
    # Acertou o vencedor
    elsif (guess_a > guess_b && match.score_a > match.score_b) ||
          (guess_a < guess_b && match.score_a < match.score_b)
      self.points = 5
    # Acertou algum dos placares
    elsif guess_a == match.score_a || guess_b == match.score_b
      self.points = 2
    else
      self.points = 0
    end

    save
  end

  def total_points
    bets.sum(:points)
  end
end
