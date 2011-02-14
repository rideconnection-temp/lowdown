require 'test_helper'

class RunsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show" do
    get :show
    assert_response :success
  end

  test "should get update" do
    get :update
    assert_response :success
  end

  test "should get show_update" do
    get :show_update
    assert_response :success
  end

  test "should get create" do
    get :create
    assert_response :success
  end

  test "should get show_create" do
    get :show_create
    assert_response :success
  end

end
