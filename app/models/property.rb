# froze_string_literal: true

class Property < ApplicationRecord
  validates :name, presence: true
  validates :headline, presence: true
  validates :description, presence: true
  validates :address_1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :country, presence: true
  validates :zip_code, presence: true

  geocoded_by :address
  after_validation :geocode, if: ->(obj){ obj.latitude.blank? and obj.longitude.blank? }

  monetize :price_cents, allow_nil: true

  has_many_attached :images, dependent: :destroy

  has_many :reviews, as: :reviewable

  has_many :favourite, dependent: :destroy
  has_many :favourite_users, through: :favourite, source: :user

  has_many :reservations, dependent: :destroy
  has_many :reserved_users, through: :reservations, source: :user

  private

  def address
    # [address_1, address_2, city, state + " " + zip_code[0,5], country].compact.join(', ') # Can't be used for fake addresses
    [state, country].compact.join(', ')
  end

  def formatted_price
    self.price.format(no_cents: true)
  end

  def default_image
    # ActiveStorage::Blob.service.send(:path_for, images.first.key)
    blob = images.first.blob
    base64_image = Base64.encode64(blob.download)
    return base64_image
  end

  def available_dates
    next_reservation = reservations.future_reservations.first
    date_format = "%b %e"
    return Date.tomorrow.strftime(date_format)..Date.today.end_of_year.strftime(date_format) unless next_reservation
    Date.tomorrow.strftime(date_format)..next_reservation.reservation_date.strftime(date_format)
  end
end
