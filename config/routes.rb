Rails.application.routes.draw do
  root 'albums#index'
  get '/authenticate', to: 'albums#authenticate'
  get '/callback', to: 'albums#callback'
  devise_for :users
end
