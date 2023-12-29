class Property < ApplicationRecord
  validates :name, presence: true
  validates :headline, presence: true
  validates :description, presence: true
  validates :address_1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :country, presence: true

  geocoded_by :address
  after_validation :geocode, if: ->(obj){ obj.latitude.blank? and obj.longitude.blank? }

  def address
    [state, country].compact.join(', ')
  end
end
