class CreateHouseholds < ActiveRecord::Migration[8.1]
  def change
    create_table :households do |t|
      t.string :name, null: false # 家族・世帯・パートナー同士の名前
      t.string :invite_code

      t.timestamps
    end
    add_index :households, :invite_code, unique: true
  end
end
