require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_attributes
    { display_name: "太郎", email: "taro@example.com", password: "password123" }
  end

  test "有効な属性であれば保存できる" do
    assert User.new(valid_attributes).valid?
  end

  test "メールアドレスが重複していると保存できない" do
    User.create!(valid_attributes)
    duplicate = User.new(valid_attributes.merge(email: "TARO@example.com"))

    assert_not duplicate.valid?
  end

  test "パスワードが8文字未満だと保存できない" do
    user = User.new(valid_attributes.merge(password: "short"))

    assert_not user.valid?
  end

  test "表示名が空だと保存できない" do
    user = User.new(valid_attributes.merge(display_name: ""))

    assert_not user.valid?
  end
end
