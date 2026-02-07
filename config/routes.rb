Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Flashcard API
  resources :decks do
    member do
      get :study
    end
    
    resources :flashcards do
      collection do
        get :due
      end
      
      member do
        post :review
      end
    end
  end
end
