require 'abnormal/helpers'

class Abnormal
  class Engine < ::Rails::Engine
    config.to_prepare do
      ActionController::Base.send :include, Abnormal::Helpers
      ActionController::Base.helper Abnormal::Helpers
    end
  end
end
