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
  def address
    # [address_1, address_2, city, state + " " + zip_code[0,5], country].compact.join(', ') # Can't be used for fake addresses
    [state, country].compact.join(', ')
  end

  monetize :price_cents, allow_nil: true
  def formatted_price
    self.price.format(no_cents: true)
  end

  has_many_attached :images, dependent: :destroy
  def default_image
    # ActiveStorage::Blob.service.send(:path_for, images.first.key)
    blob = images.first.blob
    base64_image = Base64.encode64(blob.download)
    return base64_image
  end
end
