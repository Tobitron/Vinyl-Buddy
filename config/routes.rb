Rails.application.routes.draw do
  root 'albums#index'
  devise_for :users
end
