require "test_helper"

module Api
  class CategoryTotalsControllerTest < ActionDispatch::IntegrationTest
    test "指定した月のカテゴリ別合計をJSONで返す" do
      sign_in users(:one)
      households(:one).expenses.create!(payer: users(:one), category: categories(:rent),
                                        amount: 80000, spent_on: Date.new(2026, 9, 25))

      get api_category_totals_url(month: "2026-09"), as: :json

      assert_response :success
      json = response.parsed_body
      assert_equal "2026-09", json["month"]
      # 金額の大きい順。expenses(:one) で「食費」に 3000 円が登録済み
      assert_equal [ { "name" => "家賃", "amount" => 80000 }, { "name" => "食費", "amount" => 3000 } ],
                   json["categories"]
    end

    test "他の世帯の支出は含まれない" do
      # users(:two) の世帯には expenses(:two)(食費 5000 円)だけがある
      sign_in users(:two)

      get api_category_totals_url(month: "2026-09"), as: :json

      assert_equal [ { "name" => "食費", "amount" => 5000 } ], response.parsed_body["categories"]
    end

    test "支出のない月は categories が空配列になる" do
      sign_in users(:one)

      get api_category_totals_url(month: "2026-08"), as: :json

      assert_response :success
      assert_equal [], response.parsed_body["categories"]
    end

    test "月を指定しなければ今月の合計を返す" do
      sign_in users(:one)

      travel_to Date.new(2026, 9, 21) do
        get api_category_totals_url, as: :json
      end

      assert_equal "2026-09", response.parsed_body["month"]
    end

    test "月の形式が正しくなければ400を返す" do
      sign_in users(:one)

      get api_category_totals_url(month: "abc"), as: :json

      assert_response :bad_request
    end

    test "ログインしていなければ401を返す" do
      get api_category_totals_url, as: :json

      assert_response :unauthorized
    end

    test "世帯に未所属なら404を返す" do
      sign_in create_user(email: "new@example.com")

      get api_category_totals_url, as: :json

      assert_response :not_found
    end
  end
end
