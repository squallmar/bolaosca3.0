# app/models/match.rb
class Match < ApplicationRecord
  has_many :bets, dependent: :destroy
  belongs_to :championship
  belongs_to :team_a, class_name: "Team", optional: true
  belongs_to :team_b, class_name: "Team", optional: true
  has_one_attached :team_a_logo
  has_one_attached :team_b_logo

  # Scopes
  scope :upcoming, -> { where("match_date >= ?", Time.current).order(match_date: :asc) }
  scope :past, -> { where("match_date <= ?", Time.current).order(match_date: :desc) }
  scope :with_championship, ->(limit = 5) { includes(:championship).limit(limit) }

  # Validações
  validates :team_a, :team_b, :match_date, presence: true
  validate :future_match_date
  validate :validate_logo_files
  validates :championship, presence: true

  def finalize!(home_score, away_score)
    update(
      home_team_score: home_score,
      away_team_score: away_score,
      status: "finalized",
      finalized_at: Time.current
    )

    calculate_bets_points!
    update_rankings!
  end

  # Métodos para compatibilidade
  def team_a_name
    team_a&.name || team_a
  end

  def team_b_name
    team_b&.name || team_b
  end

  def team_a_logo_or_default
    team_a&.logo || team_a_logo
  end

  def team_b_logo_or_default
    team_b&.logo || team_b_logo
  end

  private

  def calculate_bets_points!
    bets.each do |bet|
      points = calculate_points_for(bet)
      bet.update(points: points)
      bet.user.increment!(:total_points, points)
    end
  end

  def calculate_points_for(bet)
    return 0 unless finalized?

    if exact_score?(bet)
      10
    elsif correct_winner_with_goal_difference?(bet)
      7
    elsif correct_winner?(bet)
      5
    else
      0
    end
  end

  def exact_score?(bet)
    bet.home_score == home_team_score && bet.away_score == away_team_score
  end

  def correct_winner_with_goal_difference?(bet)
    (bet.home_score - bet.away_score) == (home_team_score - away_team_score)
  end

  def correct_winner?(bet)
    (bet.home_score > bet.away_score && home_team_score > away_team_score) ||
      (bet.home_score < bet.away_score && home_team_score < away_team_score) ||
      (bet.home_score == bet.away_score && home_team_score == away_team_score)
  end

  def update_rankings!
    # Atualiza rankings após calcular pontos
    Ranking.update_all_rankings
  end


  def future_match_date
    return unless match_date.present?

    if match_date <= Time.current
      errors.add(:match_date, "deve ser no futuro")
    elsif match_date > 1.year.from_now
      errors.add(:match_date, "não pode ser mais de 1 ano no futuro")
    end
  end

  def validate_logo_files
    return if team_a.present? || team_b.present?

    [ team_a_logo, team_b_logo ].each do |logo|
      if logo.attached?
        unless logo.content_type.in?(%w[image/jpeg image/png])
          errors.add(:base, "Os escudos devem ser no formato JPG ou PNG")
        end

        if logo.byte_size > 2.megabytes
          errors.add(:base, "Cada escudo deve ter no máximo 2MB")
        end
      end
    end
  end
end
