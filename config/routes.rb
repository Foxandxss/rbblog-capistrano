Capistrano::Application.routes.draw do
  route to: "languages#index"

  resources :languages

end
