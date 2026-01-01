Rails.application.routes.draw do
  # Signup
  get 'signup', to: 'users#new', as: 'new_user'
  post 'users', to: 'users#create'
  resources :users, only: [:show]   # Needed for profiles & friend lists

  # Login/Logout
  root 'sessions#new'
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # Root → Chatroom
  get 'chatroom', to: 'chatroom#index'

  # Messages (global chat)
  resources :messages, only: [:create]

  # Friendships (remove friends only - adding now goes through friend requests)
  resources :friendships, only: [:destroy]

  # Friend Requests
  resources :friend_requests, only: [:create] do
    member do
      post :accept
      post :reject
      post :cancel
    end
  end

  # Direct Message Conversations (DM system)
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]  # nested messages for each conversation
  end
end

