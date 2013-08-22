require 'castronaut/application'
Cosigntronaut::Application.set(:path, "/cosign_server")

Scenario::Application.routes.draw do
  devise_for :users
  mount Cosigntronaut::Application, :at => "/cosign_server"
  root :to => "home#index"
end
