class Profile < ApplicationRecord
  belongs_to :user

  geocoded_by :address
  after_validation :geocode

  def address
    ["#{state} #{zip_code}", country].compact.join(', ')
  end
end
