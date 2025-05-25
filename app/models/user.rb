class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  # Associations
  has_many :bets, dependent: :destroy
  has_many :matches, through: :bets
  mount_uploader :avatar_url, AvatarUploader

  # Validations
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :admin, inclusion: { in: [ true, false ] }

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
  # ----------------------------Método para o ranking--------------------------------------- #
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

  # ---------------------------------------------------------------------------------------- #
  def avatar_url
    super || ActionController::Base.helpers.asset_path("default-avatar.png")
  end

  private

  def admin_emails
    ENV.fetch("ADMIN_EMAILS", "admin@example.com").split(",").map(&:strip).map(&:downcase)
  end
end
