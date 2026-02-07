require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "password123"
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email (case insensitive)" do
    @user.save!
    duplicate = User.new(email: "TEST@example.com", password: "password123")
    assert_not duplicate.valid?
  end

  test "should require valid email format" do
    @user.email = "not-an-email"
    assert_not @user.valid?
  end

  test "should require password at least 8 characters" do
    @user.password = "short"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "should generate valid JWT" do
    @user.save!
    token = @user.generate_jwt
    assert_not_nil token
    assert_kind_of String, token
  end

  test "should decode valid JWT" do
    @user.save!
    token = @user.generate_jwt
    decoded_user = User.decode_jwt(token)
    assert_equal @user, decoded_user
  end

  test "should return nil for invalid JWT" do
    decoded = User.decode_jwt("invalid.token.here")
    assert_nil decoded
  end

  test "should have many conversations" do
    assert_respond_to @user, :conversations
  end

  test "should have many decks" do
    assert_respond_to @user, :decks
  end

  test "should have many flashcards" do
    assert_respond_to @user, :flashcards
  end
end
