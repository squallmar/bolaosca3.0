# app/models/match.rb
class Match < ApplicationRecord
  # Associações
  has_many :bets, dependent: :destroy
  belongs_to :championship
  belongs_to :team_a, class_name: "Team", optional: true
  belongs_to :team_b, class_name: "Team", optional: true
  has_one_attached :team_a_logo
  has_one_attached :team_b_logo
  belongs_to :round, optional: true

  # Enum para o status da partida
  enum :status, { agendado: 0, em_andamento: 1, finalizado: 2, cancelado: 3 }, default: :agendado

  # Validações
  validates :team_a_id, :team_b_id, presence: true
  validates :team_a, :team_b, :match_date, presence: true
  validates :championship, presence: true
  validates :match_date, uniqueness: { scope: [:team_a_id, :team_b_id],
                                   message: "já existe uma partida agendada com esses times na mesma data." }
  validate :future_match_date, if: :new_record?
  validate :validate_logo_files
  validate :teams_must_be_different

  # Scopes
  scope :upcoming, -> { where("match_date >= ?", Time.current).order(match_date: :asc) }
  scope :past, -> { where("match_date <= ?", Time.current).order(match_date: :desc) }
  scope :with_championship, ->(limit = 5) { includes(:championship).limit(limit) }
  scope :finalized, -> { where(status: :finalizado) }

  # Callbacks
  after_update_commit :calculate_points_for_bets, if: -> { saved_change_to_status?(to: 'finalizado') && score_a.present? && score_b.present? }

  # Métodos de Instância
  def can_be_finalized?
    !finalizado? && match_date.present? && match_date <= Time.current && team_a.present? && team_b.present?
  end

  def status_finalized?
    status == 'finalizado'
  end

  def finished?
    status == "finished"
  end

  def in_progress?
    status == "in_progress"
  end

  def team_a_name
    team_a&.name || "Time A"
  end

  def team_b_name
    team_b&.name || "Time B"
  end

  def team_a_logo_or_default
    team_a&.logo.attached? ? team_a.logo : (team_a_logo.attached? ? team_a_logo : "default_team.png")
  end

  def team_b_logo_or_default
    team_b&.logo.attached? ? team_b.logo : (team_b_logo.attached? ? team_b_logo : "default_team.png")
  end

  private

  def calculate_points_for_bets
    bets.confirmed.includes(:user).find_each do |bet|
      bet.calculate_points!
    end
  end

  def future_match_date
    return unless match_date.present?

    if match_date <= Time.current
      errors.add(:match_date, "deve ser no futuro ao agendar uma nova partida.")
    elsif match_date > 1.year.from_now
      errors.add(:match_date, "não pode ser mais de 1 ano no futuro.")
    end
  end

  def validate_logo_files
    [team_a_logo, team_b_logo].each do |logo|
      next unless logo.attached?

      unless logo.content_type.in?(%w[image/jpeg image/png])
        errors.add(:base, "Os escudos devem ser no formato JPG ou PNG")
      end

      if logo.byte_size > 2.megabytes
        errors.add(:base, "Cada escudo deve ter no máximo 2MB")
      end
    end
  end

  def teams_must_be_different
    if team_a_id.present? && team_b_id.present? && team_a_id == team_b_id
      errors.add(:base, "Os times da partida devem ser diferentes.")
    end
  end
end