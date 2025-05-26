class Championship < ApplicationRecord
  has_many :matches
  has_and_belongs_to_many :teams
  has_one_attached :logo
  
  attribute :active, :boolean, default: true
  before_validation :set_default_active, on: :create
  
  validates :name, :start_date, presence: true
  validate :end_date_after_start_date

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def active?
    active
  end

  def status
    active? ? 'Ativo' : 'Finalizado'
  end

  private

  def set_default_active
    self.active = true if active.nil?
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "não pode ser anterior à data de início") if end_date < start_date
  end
end