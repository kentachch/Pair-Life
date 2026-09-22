namespace :categories do
  # 実行方法：docker compose exec web bin/rails categories:add_defaults
  desc "既存の世帯に、足りない初期カテゴリを追加する(何度実行しても重複しない)"
  task add_defaults: :environment do
    Household.find_each do |household|
      household.add_default_categories!
      puts "#{household.name}(id: #{household.id}):カテゴリ #{household.categories.count} 件"
    end
  end
end
