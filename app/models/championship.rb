class Championship < ApplicationRecord
  has_many :matches
  attribute :active, :boolean, default: true
  before_validation :set_default_active, on: :create
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

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "deve ser após a data de início") if end_date < start_date
  end

  def set_default_active
    self.active = true if active.nil?
  end
end
