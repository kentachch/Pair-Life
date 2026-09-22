module HomeHelper
  def calendar_weeks(month)
    first_day = month.beginning_of_month.beginning_of_week(:sunday)
    # beginning_of_month/ beginning_of_week(:sunday)は、Railsが用意しているメソッド

    last_day = month.end_of_month.end_of_week(:sunday)
    (first_day..last_day).each_slice(7).to_a
    # A..Bは、rubyのrangeの書き方
    # each_slice(7)で、7個ずつに分割
    # to_a：配列に変換
  end
end
