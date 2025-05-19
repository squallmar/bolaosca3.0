class User < ApplicationRecord
  # Relacionamentos
  has_many :bets, dependent: :destroy
  has_many :matches, through: :bets
  mount_uploader :avatar_url, AvatarUploader

  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Validações
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :admin, inclusion: { in: [ true, false ] }

  # Atributos
  attribute :admin, :boolean, default: false
  attr_accessor :current_password

  scope :latest, ->(limit = 5) { order(created_at: :desc).limit(limit) }
  scope :active_since, ->(time) { where("last_sign_in_at >= ?", time) }

  # Métodos
  def admin?
    admin || (email.present? && emails_administradores.include?(email.downcase))
  end

  def name
    email.split("@").first.capitalize
  end

  def total_points
    self[:total_points] || calculate_total_points
  end

  def recent_bets(limit = 5)
    bets.includes(:match).order(created_at: :desc).limit(limit)
  end

  def self.top_scorers(limit = 5)
    left_joins(:bets)
      .select("users.*, COALESCE(SUM(bets.points), 0) as total_points")
      .group("users.id")
      .order("total_points DESC")
      .limit(limit)
  end

  private

  def calculate_total_points
    bets.sum(:points)
  end

  def emails_administradores
    ENV.fetch("ADMIN_EMAILS", "marcelmendes05@gmail.com").split(",")
  end
end
