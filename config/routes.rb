Capistrano::Application.routes.draw do
  root to: "languages#index"

  resources :languages

end
