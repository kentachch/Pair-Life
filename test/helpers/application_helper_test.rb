require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # ヘルパーのテストでは、Gem が用意したヘルパー(lucide_icon)が自動で読み込まれないため追加する
  include LucideRails::RailsHelper

  test "share_percent は合計に対する割合を整数で返す" do
    assert_equal 60, share_percent(120_000, 200_000)
    assert_equal 40, share_percent(80_000, 200_000)
  end

  test "share_percent は四捨五入する" do
    # 1 / 3 = 33.33...% → 33、2 / 3 = 66.66...% → 67
    assert_equal 33, share_percent(1, 3)
    assert_equal 67, share_percent(2, 3)
  end

  test "share_percent は合計が 0 のとき 0 を返す" do
    assert_equal 0, share_percent(0, 0)
  end

  test "category_icon はアイコン名を data-icon に持つ丸を返す" do
    html = category_icon(categories(:food))

    assert_includes html, 'data-icon="shopping-basket"'
    assert_includes html, "<svg"
  end
end
