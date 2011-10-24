Rails3::Application.routes.draw do
  match 'abnormal(/:action)' => 'abnormal/dashboard#index'
  match ':action' => 'application#index'
end
