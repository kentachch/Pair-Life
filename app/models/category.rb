class Category < ApplicationRecord
  belongs_to :household
  has_many :expenses, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 20 },
  uniqueness: { scope: :household_id }
end
