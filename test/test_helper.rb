ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Use threads on Windows (fork not supported), limit workers to avoid exhausting DB pool
    parallelize(workers: Gem.win_platform? ? 1 : :number_of_processors, with: :threads)

    # Add Factory Bot methods
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
  end
end

module AuthTestHelper
  def auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end
end

class ActionDispatch::IntegrationTest
  include AuthTestHelper
end
