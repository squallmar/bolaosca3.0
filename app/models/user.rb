class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  # Associations
  has_many :bets, dependent: :destroy
  has_many :matches, through: :bets
  has_one_attached :avatar

  # Validations
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :admin, inclusion: { in: [true, false] }
  validate :avatar_content_type, if: -> { avatar.attached? }
  validate :avatar_size, if: -> { avatar.attached? }

  # Attributes
  attribute :admin, :boolean, default: false
  attribute :total_points, :integer, default: 0

  # Scopes
  scope :latest, ->(limit = 5) { order(created_at: :desc).limit(limit) }
  scope :active_since, ->(time) { where("last_sign_in_at >= ?", time) }
  scope :top_scorers, ->(limit = 5) {
    left_joins(:bets)
      .select("users.*, COALESCE(SUM(bets.points), 0) as total_points")
      .group("users.id")
      .order(total_points: :desc)
      .limit(limit)
  }

  # Instance Methods
  def admin?
    admin || admin_emails.include?(email.downcase)
  end

  def name
    self[:name] || full_name.presence || email.split("@").first.capitalize
  end

  def display_name
    name.presence || "Usuário ##{id}"
  end

  def update_total_points
    update_column(:total_points, bets.confirmed.sum(:points))
  end

  def recent_bets(limit = 5)
    bets.includes(:match)
        .order(created_at: :desc)
        .limit(limit)
  end

  def self.ranked
    order(total_points: :desc)
  end

  # Métodos para o ranking
  def exact_score_count
    bets.confirmed.joins(:match)
        .where(matches: { status: :finalizado })
        .where("bets.guess_a = matches.score_a AND bets.guess_b = matches.score_b")
        .count
  end

  def correct_winner_count
    bets.confirmed.joins(:match)
        .where(matches: { status: :finalizado })
        .where("(bets.guess_a > bets.guess_b AND matches.score_a > matches.score_b) OR
                (bets.guess_a < bets.guess_b AND matches.score_a < matches.score_b) OR
                (bets.guess_a = bets.guess_b AND matches.score_a = matches.score_b)")
        .count
  end

  # Métodos para avatar e iniciais
  def avatar_url
    if avatar.attached?
      avatar
    else
      ActionController::Base.helpers.asset_path("default-avatar.png")
    end
  end

  def name_initials
    return '?' if name.blank?
    
    name.unicode_normalize(:nfkd)
        .gsub(/[^\x00-\x7F]/, '')
        .split
        .map { |part| part[0]&.upcase }
        .compact
        .join[0..1]
  rescue
    '?'
  end

  def initials_color
    colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8']
    colors[name_initials.sum % colors.size]
  end

  def correct_bets_percentage
    total_bets = bets.confirmed.joins(:match).where(matches: { status: :finalizado }).count
    return 0 if total_bets.zero?

    correct_bets = bets.confirmed.joins(:match)
                      .where(matches: { status: :finalizado })
                      .where("(bets.guess_a = matches.score_a AND bets.guess_b = matches.score_b) OR
                              ((bets.guess_a > bets.guess_b AND matches.score_a > matches.score_b) OR
                                (bets.guess_a < bets.guess_b AND matches.score_a < matches.score_b))")
                      .count

    ((correct_bets.to_f / total_bets) * 100).round(1)
    end
  end

  def correct_bets_percentage
  Rails.cache.fetch("#{cache_key_with_version}/correct_bets_percentage", expires_in: 12.hours) do
    
  end

  after_save :update_correct_percentage, if: :saved_change_to_points?


  private

  def update_correct_percentage
    update_column(:correct_bets_percentage, calculate_correct_percentage)
  end

  def admin_emails
    ENV.fetch("ADMIN_EMAILS", "admin@example.com").split(",").map(&:strip).map(&:downcase)
  end

  def avatar_content_type
    unless avatar.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:avatar, 'deve ser uma imagem JPEG, PNG ou GIF')
    end
  end

  def avatar_size
    if avatar.blob.byte_size > 2.megabytes
      errors.add(:avatar, 'não pode ser maior que 2MB')
    end
  end
end
