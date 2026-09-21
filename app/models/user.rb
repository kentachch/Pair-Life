class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :name, presence: true

  has_one :household_member, dependent: :destroy
  has_one :household, through: :household_member
end
