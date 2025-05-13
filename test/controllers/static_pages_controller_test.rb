require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get termos" do
    get static_pages_termos_url
    assert_response :success
  end

  test "should get privacidade" do
    get static_pages_privacidade_url
    assert_response :success
  end
end
