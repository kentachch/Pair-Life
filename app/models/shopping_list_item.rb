class ShoppingListItem < ApplicationRecord
  belongs_to :shopping_list
  belongs_to :added_by
end
