class CreateHouseholdMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :household_members do |t|
      t.references :household, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :burden_ratio, null: false, default: 50

      t.timestamps
    end
  end
end
