class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_abnormal_identity

  def set_abnormal_identity
    if session[:abnormal_identity]
      Abnormal.identity = session[:abnormal_identity]
    else
      Abnormal.identity = session[:abnormal_identity] = rand(10**20).to_i
    end
  end

  def reset
    Abnormal.identity = session[:abnormal_identity] = rand(10**20).to_i
    redirect_to :back
  end

  def view_basic
  end

  def controller_basic
    @alternative = ab_test 'test1', [1, 2], 'nothing'
  end

  def convert1
    convert! 'c1'
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to :action => 'view_basic'
  end

  def convert1x
    convert! 'c1', 2
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to :action => 'view_basic'
  end

  def convert2
    convert! 'c2'
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to :action => 'view_basic'
  end
end
