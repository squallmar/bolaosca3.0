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
    update_column(:total_points, bets.sum(:points))
  end

  def recent_bets(limit = 5)
    bets.includes(:match)
        .order(created_at: :desc)
        .limit(limit)
  end

  def self.ranked
    order(total_points: :desc)
  end

  def exact_score_count
    bets.where(points: 10).count
  end

  def correct_winner_count
    bets.where(points: [ 5, 7 ]).count
  end

    def avatar_url
      super || ActionController::Base.helpers.asset_path("default-avatar.png")
    end

  private

  def admin_emails
    ENV.fetch("ADMIN_EMAILS", "admin@example.com").split(",").map(&:strip).map(&:downcase)
  end
end
