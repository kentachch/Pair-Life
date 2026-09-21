class Category < ApplicationRecord
  belongs_to :household

  validates :name, presence: true, length: { maximum: 20 },
  uniqueness: { scope: :household_id }
end
