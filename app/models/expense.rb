class Expense < ApplicationRecord
  belongs_to :household
  belongs_to :payer
  belongs_to :category
end
