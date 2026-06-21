Rails.application.routes.draw do
  mount Pinnable::Engine => "/pinnable"

  get "/sign_in/:id", to: "test_sessions#create"
  get "/dashboard",   to: "pages#dashboard"
end
