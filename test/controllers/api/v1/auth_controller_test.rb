require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  def setup
    @valid_user_params = {
      email: "newuser@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
    @existing_user = User.create!(
      email: "existing@example.com",
      password: "password123"
    )
  end

  # Registration Tests
  test "should register new user with valid params" do
    assert_difference "User.count", 1 do
      post api_v1_auth_register_url, params: @valid_user_params
    end
    assert_response :created
    
    json = JSON.parse(response.body)
    assert_not_nil json["token"]
    assert_equal "newuser@example.com", json["user"]["email"]
  end

  test "should not register user with invalid email" do
    post api_v1_auth_register_url, params: {
      email: "not-an-email",
      password: "password123"
    }
    assert_response :unprocessable_entity
  end

  test "should not register user with short password" do
    post api_v1_auth_register_url, params: {
      email: "valid@example.com",
      password: "short"
    }
    assert_response :unprocessable_entity
  end

  test "should not register user with duplicate email" do
    post api_v1_auth_register_url, params: {
      email: "existing@example.com",
      password: "password123"
    }
    assert_response :unprocessable_entity
  end

  # Login Tests
  test "should login with valid credentials" do
    post api_v1_auth_login_url, params: {
      email: "existing@example.com",
      password: "password123"
    }
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_not_nil json["token"]
    assert_equal "existing@example.com", json["user"]["email"]
  end

  test "should not login with wrong password" do
    post api_v1_auth_login_url, params: {
      email: "existing@example.com",
      password: "wrongpassword"
    }
    assert_response :unauthorized
  end

  test "should not login with nonexistent email" do
    post api_v1_auth_login_url, params: {
      email: "nonexistent@example.com",
      password: "password123"
    }
    assert_response :unauthorized
  end

  test "login is case insensitive for email" do
    post api_v1_auth_login_url, params: {
      email: "EXISTING@EXAMPLE.COM",
      password: "password123"
    }
    assert_response :success
  end

  # Me Endpoint Tests
  test "should return current user with valid token" do
    token = @existing_user.generate_jwt
    get api_v1_auth_me_url, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal "existing@example.com", json["user"]["email"]
  end

  test "should not return user without token" do
    get api_v1_auth_me_url
    assert_response :unauthorized
  end

  test "should not return user with invalid token" do
    get api_v1_auth_me_url, headers: { "Authorization" => "Bearer invalid.token.here" }
    assert_response :unauthorized
  end
end
