class User < ApplicationRecord
  has_secure_password

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true, uniqueness: true
  normalizes :email, with: -> email { email.strip.downcase }

  generates_token_for :password_reset, expires_in: 15.minutes do
    # `password_salt` (defined by `has_secure_password`) returns the salt for
    # the password. The salt changes when the password is changed, so the token
    # will expire when the password is changed.
    password_salt&.last(10)
  end

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email + confirmed_at.to_s
  end

  has_one :profile, dependent: :destroy
  after_create :create_profile

  has_many :favourite, dependent: :destroy
  has_many :favourite_properties, through: :favourite, source: :property

  has_many :reservations, dependent: :destroy
  has_many :reserved_properties, through: :reservations, source: :user

  private

  def create_profile
    self.profile = Profile.new
    save!
  end
end
