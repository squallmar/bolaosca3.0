class Bet < ApplicationRecord
  # Enums
  enum :status, { pending: 0, confirmed: 1, canceled: 2 }, prefix: true
  
  # Associações
  belongs_to :user
  belongs_to :match

  # Validações
  validates :guess_a, :guess_b,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }
  validate :validate_guess_status

  # Callbacks
  after_save :calculate_points, if: :should_calculate_points?

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :confirmed, -> { where(status: :confirmed) }
  scope :canceled, -> { where(status: :canceled) }
  scope :with_points, -> { where.not(points: nil) }

  # Métodos públicos
  def calculate_points!
    return unless calculable?

    update(points: calculate_points_value)
    user.update_total_points
  end

  def exact?
    guess_a == match.score_a && guess_b == match.score_b
  end

  def correct_winner?
    (guess_a > guess_b && match.score_a > match.score_b) ||
    (guess_a < guess_b && match.score_a < match.score_b) ||
    (guess_a == guess_b && match.score_a == match.score_b)
  end

  private

  def should_calculate_points?
    saved_change_to_status?(to: "confirmed") ||
    (status_confirmed? && saved_change_to_guess_a_or_guess_b?)
  end

  def calculable?
    status_confirmed? && match.status_finalized?
  end

  def calculate_points_value
    if exact?
      10
    elsif correct_goal_difference?
      7
    elsif correct_winner?
      5
    elsif partial_correct?
      2
    else
      0
    end
  end

  def correct_goal_difference?
    (guess_a - guess_b) == (match.score_a - match.score_b)
  end

  def partial_correct?
    guess_a == match.score_a || guess_b == match.score_b
  end

  def saved_change_to_guess_a_or_guess_b?
    saved_change_to_guess_a? || saved_change_to_guess_b?
  end

  def validate_guess_status
    if status_confirmed? && (guess_a.blank? || guess_b.blank?)
      errors.add(:base, "Palpites não podem estar em branco para status 'confirmed'")
    end
  end
end
