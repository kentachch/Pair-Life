class Category < ApplicationRecord
  ICONS = %w[
    house droplet zap flame shopping-basket spray-can utensils coffee
    shapes gift circle-ellipsis tag train-front car fuel heart-pulse
    pill shirt scissors baby dog graduation-cap book-open smartphone
    wifi gamepad-2 film plane dumbbell piggy-bank
  ].freeze

  DEFAULT_ICON = "tag".freeze

  belongs_to :household
  has_many :expenses, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 20 },
  uniqueness: { scope: :household_id }
  validates :icon, inclusion: { in: ICONS }
end
