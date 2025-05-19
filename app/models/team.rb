class Team < ApplicationRecord
  has_one_attached :logo
  has_many :home_matches, class_name: "Match", foreign_key: "team_a_id", dependent: :nullify
  has_many :away_matches, class_name: "Match", foreign_key: "team_b_id", dependent: :nullify

  validates :name, presence: true, uniqueness: true

  # Validações do logo
  validate :correct_logo_type

  scope :latest, ->(limit = 5) { order(created_at: :desc).limit(limit) }

  private

  def correct_logo_type
    if logo.attached?
      unless logo.content_type.in?(%w[image/jpeg image/png])
        errors.add(:logo, "deve ser um JPEG ou PNG")
      end

      if logo.byte_size > 2.megabytes
        errors.add(:logo, "não pode exceder 2MB")
      end
    end
  end
end
