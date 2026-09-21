ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # フィクスチャ以外のユーザーが必要なテストで使う
    def create_user(email:, name: "テストユーザー")
      User.create!(email: email, name: name, password: "password")
    end
  end
end

module ActionDispatch
  class IntegrationTest
    # Devise の sign_in / sign_out をテストで使えるようにする
    include Devise::Test::IntegrationHelpers
  end
end
