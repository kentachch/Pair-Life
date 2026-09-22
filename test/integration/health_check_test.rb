require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  # Render は /up が 200 を返すかどうかで、デプロイが成功したかを判断する
  test "/up はログインしていなくても 200 を返す" do
    get "/up"

    assert_response :success
  end
end
