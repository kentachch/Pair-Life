class Settlement < ApplicationRecord
  belongs_to :household
  belongs_to :from_user
  belongs_to :to_user
end
