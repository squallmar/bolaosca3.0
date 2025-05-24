class Match < ApplicationRecord
  has_many :bets, dependent: :destroy
  belongs_to :championship
  belongs_to :team_a, class_name: "Team", optional: true
  belongs_to :team_b, class_name: "Team", optional: true
  has_one_attached :team_a_logo
  has_one_attached :team_b_logo

  enum :status, { scheduled: 0, finalized: 1 }, prefix: true

  validates :team_a_id, :team_b_id, presence: true
  validates :team_a_id, uniqueness: { scope: [ :team_b_id, :match_date ], message: "já existe uma partida agendada com esses times na mesma data" }
  validates :team_b_id, uniqueness: { scope: [ :team_a_id, :match_date ], message: "já existe uma partida agendada com esses times na mesma data" }
  validates :team_a, :team_b, :match_date, presence: true
  validates :championship, presence: true

  validate :future_match_date
  validate :validate_logo_files

  scope :upcoming, -> { where("match_date >= ?", Time.current).order(match_date: :asc) }
  scope :past, -> { where("match_date <= ?", Time.current).order(match_date: :desc) }
  scope :with_championship, ->(limit = 5) { includes(:championship).limit(limit) }

  after_update :update_rankings, if: :saved_change_to_status?

  def can_be_finalized?
    !status_finalized? &&
      match_date.present? &&
      match_date <= Time.current &&
      team_a.present? &&
      team_b.present?
  end

  def finalize!(home_score, away_score)
    update(
      home_team_score: home_score,
      away_team_score: away_score,
      status: :finalized,
      finalized_at: Time.current
    )
  end

  # Métodos para compatibilidade
  def team_a_name
    team_a&.name || "Time A"
  end

  def team_b_name
    team_b&.name || "Time B"
  end

  def team_a_logo_or_default
    team_a&.logo || team_a_logo || "default_team.png"
  end

  def team_b_logo_or_default
    team_b&.logo || team_b_logo || "default_team.png"
  end

  private

  def update_rankings
    return unless status_finalized?

    # Atualiza pontos de todos os palpites desta partida
    bets.includes(:user).find_each do |bet|
      points = calculate_points_for(bet)
      bet.update(points: points)
      bet.user.update_total_points
    end
  end

  def calculate_points_for(bet)
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

  def future_match_date
    return unless match_date.present?

    if match_date <= Time.current && !status_finalized?
      errors.add(:match_date, "deve ser no futuro para partidas não finalizadas")
    elsif match_date > 1.year.from_now
      errors.add(:match_date, "não pode ser mais de 1 ano no futuro")
    end
  end

  def validate_logo_files
    [ team_a_logo, team_b_logo ].each do |logo|
      next unless logo.attached?

      unless logo.content_type.in?(%w[image/jpeg image/png])
        errors.add(:base, "Os escudos devem ser no formato JPG ou PNG")
      end

      if logo.byte_size > 2.megabytes
        errors.add(:base, "Cada escudo deve ter no máximo 2MB")
      end
    end
  end
end
