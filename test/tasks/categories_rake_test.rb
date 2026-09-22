require "test_helper"
require "rake"

class CategoriesRakeTest < ActiveSupport::TestCase
  setup do
    # rake タスクをテストから呼べるように読み込む(1回だけ)
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["categories:add_defaults"].reenable
  end

  test "categories:add_defaults で、すべての世帯に初期カテゴリがそろう" do
    assert_output(/カテゴリ #{Household::DEFAULT_CATEGORIES.size} 件/) do
      Rake::Task["categories:add_defaults"].invoke
    end

    Household.find_each do |household|
      assert_equal Household::DEFAULT_CATEGORIES.keys.sort,
                   household.categories.where(name: Household::DEFAULT_CATEGORIES.keys).pluck(:name).sort
    end
  end
end
