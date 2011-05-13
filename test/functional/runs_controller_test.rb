require 'test_helper'

class RunsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:admin)
  end
  test "should get index" do

    get :index
    assert_response :success
  end

  test "should get create" do
    get :create
    assert_response :success
  end

end
