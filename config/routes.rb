Pinnable::Engine.routes.draw do
  resources :pins, only: %i[index show create update], param: :public_id
  root to: "pins#index"
  resources :markers, only: :index
end
