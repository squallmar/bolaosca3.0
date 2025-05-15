class User < ApplicationRecord
  # Relacionamentos
  has_many :bets, dependent: :destroy
  has_many :matches, through: :bets
  mount_uploader :avatar_url, AvatarUploader

  # Módulos do Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable   # rastreamento de login

  # Validações
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :admin, inclusion: { in: [ true, false ] }

  # Atributo virtual para senha atual (útil para atualizações)
  attr_accessor :current_password

  # Define o valor padrão para o atributo admin
  attribute :admin, :boolean, default: false

  # Métodos
  def admin?
    admin || email.in?(emails_administradores)
  end

  def name
  email.split("@").first.capitalize
  end

  # Pontuação total do usuário no bolão
  def total_points
    bets.sum(:points)
  end

  # Últimos palpites do usuário
  def recent_bets(limit = 5)
    bets.includes(:match).order(created_at: :desc).limit(limit)
  end

  private

  # Lista de emails administradores (pode ser movida para config depois)
  def emails_administradores
    [
      "marcelmendes05@gmail.com"
    ].freeze
  end
end
