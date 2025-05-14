class Match < ApplicationRecord
  has_many :bets, dependent: :destroy
  belongs_to :championship
  has_one_attached :team_a_logo
  has_one_attached :team_b_logo

  validates :team_a, :team_b, :match_date, presence: true
  validate :future_match_date
  validate :validate_logo_files

  private

  def future_match_date
    return unless match_date.present?

    if match_date <= Time.current
      errors.add(:match_date, "deve ser no futuro")
    elsif match_date > 1.year.from_now
      errors.add(:match_date, "não pode ser mais de 1 ano no futuro")
    end
  end

  def validate_logo_files
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
