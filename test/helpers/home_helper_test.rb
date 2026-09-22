require "test_helper"

class HomeHelperTest < ActionView::TestCase
  test "カレンダーは1日を含む週の日曜日から始まる" do
    weeks = calendar_weeks(Date.new(2026, 9, 1))

    # 2026年9月1日は火曜日なので、その週の日曜日は8月30日
    assert_equal Date.new(2026, 8, 30), weeks.first.first
  end

  test "カレンダーは月末を含む週の土曜日で終わる" do
    weeks = calendar_weeks(Date.new(2026, 9, 1))

    # 2026年9月30日は水曜日なので、その週の土曜日は10月3日
    assert_equal Date.new(2026, 10, 3), weeks.last.last
  end

  test "どの週も7日ある" do
    weeks = calendar_weeks(Date.new(2026, 9, 1))

    assert_equal 5, weeks.size
    assert weeks.all? { |week| week.size == 7 }
  end

  test "月の途中の日付を渡しても、その月のカレンダーになる" do
    assert_equal calendar_weeks(Date.new(2026, 9, 1)), calendar_weeks(Date.new(2026, 9, 21))
  end
end
