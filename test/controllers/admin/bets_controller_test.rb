require "test_helper"

class Admin::BetsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_bets_index_url
    assert_response :success
  end
end
