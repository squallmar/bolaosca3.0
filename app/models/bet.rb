class Bet < ApplicationRecord
  belongs_to :user
  belongs_to :match

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :confirmed, -> { where(status: :confirmed) }
  scope :canceled, -> { where(status: :canceled) }

  # Validações
  validates :guess_a, :guess_b, presence: true
  validates :guess_a, :guess_b, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }

  # Callbacks
  after_save :calculate_points, if: -> { saved_change_to_status?(to: "confirmed") }

  # Métodos
  def validate_guess_status
    if guess_a.blank? || guess_b.blank?
      errors.add(:base, "Palpites não podem estar em branco para status 'confirmed'")
    end
  end

  def calculate_points
    return unless match.finished? && confirmed?

    self.points = calculate_points_logic
    save
  end

  private

  def calculate_points_logic
    # Acertou o placar exato
    if exact_score?
      10
    # Acertou a diferença de gols
    elsif correct_goal_difference?
      7
    # Acertou o vencedor
    elsif correct_winner?
      5
    # Acertou algum placar parcial
    elsif partial_correct?
      2
    else
      0
    end
  end

  def exact_score?
    guess_a == match.score_a && guess_b == match.score_b
  end

  def correct_goal_difference?
    (guess_a - guess_b) == (match.score_a - match.score_b)
  end

  def correct_winner?
    (guess_a > guess_b && match.score_a > match.score_b) ||
    (guess_a < guess_b && match.score_a < match.score_b)
  end

  def partial_correct?
    guess_a == match.score_a || guess_b == match.score_b
  end
end
