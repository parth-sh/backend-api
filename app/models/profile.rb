class Profile < ApplicationRecord
  belongs_to :user

  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? and obj.latitude.blank? and obj.longitude.blank? }

  def address
    ["#{state} #{zip_code}", country].compact.join(', ')
  end
end
