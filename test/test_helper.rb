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

    # ペア（2人組）をテストデータとして作成する。
    def create_pair!(user_a_name: "自分", user_b_name: "相手")
      user_a = User.create!(display_name: user_a_name, email: "#{SecureRandom.hex(6)}@example.com", password: "password123")
      user_b = User.create!(display_name: user_b_name, email: "#{SecureRandom.hex(6)}@example.com", password: "password123")
      pair = Pair.create!(pair_name: "テストペア", created_by: user_a.id)
      PairMember.create!(pair: pair, user: user_a, joined_at: Time.current)
      PairMember.create!(pair: pair, user: user_b, joined_at: Time.current)
      [ pair.reload, user_a, user_b ]
    end
  end
end
