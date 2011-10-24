require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  test "basic view test" do
    session[:abnormal_identity] = 'ident'
    mock(Abnormal).ab_test('ident', 'test1', [1, 2], 'nothing') { 'alternative' }

    get :view_basic

    assert_select '#alt', 'alternative'
  end

  test "basic controller test" do
    session[:abnormal_identity] = 'ident'
    mock(Abnormal).ab_test('ident', 'test1', [1, 2], 'nothing') { 'alternative' }

    get :controller_basic

    assert_select '#alt', 'alternative'
  end

  test "conversion" do
    session[:abnormal_identity] = 'ident'
    mock(Abnormal).convert!('ident', 'c1')

    get :convert1
  end

  test "multiple conversion" do
    session[:abnormal_identity] = 'ident'
    mock(Abnormal).convert!('ident', 'c1', 2)

    get :convert1x
  end
end
