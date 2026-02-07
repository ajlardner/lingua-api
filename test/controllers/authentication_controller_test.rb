require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "test@example.com", password: "password123")
  end

  # === Register ===

  test "should register new user" do
    assert_difference("User.count") do
      post auth_register_url, params: {
        email: "new@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert_equal "new@example.com", json["user"]["email"]
  end

  test "should not register with invalid email" do
    assert_no_difference("User.count") do
      post auth_register_url, params: {
        email: "",
        password: "password123"
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not register with duplicate email" do
    assert_no_difference("User.count") do
      post auth_register_url, params: {
        email: "test@example.com",
        password: "password123"
      }
    end

    assert_response :unprocessable_entity
  end

  # === Login ===

  test "should login with valid credentials" do
    post auth_login_url, params: {
      email: "test@example.com",
      password: "password123"
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert_equal @user.id, json["user"]["id"]
  end

  test "should not login with invalid password" do
    post auth_login_url, params: {
      email: "test@example.com",
      password: "wrongpassword"
    }

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_match(/Invalid/, json["error"])
  end

  test "should not login with unknown email" do
    post auth_login_url, params: {
      email: "unknown@example.com",
      password: "password123"
    }

    assert_response :unauthorized
  end

  # === Me ===

  test "should get current user with valid token" do
    token = JsonWebToken.encode(user_id: @user.id)

    get auth_me_url, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @user.id, json["user"]["id"]
  end

  test "should not get current user without token" do
    get auth_me_url

    assert_response :unauthorized
  end

  test "should not get current user with invalid token" do
    get auth_me_url, headers: { "Authorization" => "Bearer invalid-token" }

    assert_response :unauthorized
  end
end
