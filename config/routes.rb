require 'sidekiq/web'
require 'sidekiq-status/web'

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
end if Rails.env.production?

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/docs'
  mount Rswag::Api::Engine => '/docs'
  
  mount Sidekiq::Web => "/sidekiq"
  mount PgHero::Engine, at: "pghero"

  namespace :api, :defaults => {:format => :json} do
    namespace :v1 do
      resources :jobs

      resources :topics, only: [:index, :show]

      resources :list_projects, only: [:index]

      resources :lists, constraints: { id: /.*/ }, only: [:index, :show] do
        resources :list_projects, only: [:index]
        resources :projects, constraints: { id: /.*/ }, only: [:index]
        collection do
          get :lookup
        end
      end
      resources :projects, constraints: { id: /.*/ }, only: [:index, :show] do
        resources :lists, constraints: { id: /.*/ }, only: [:index]
        collection do
          get :lookup
        end
        member do
          get :ping
        end
      end
    end
  end

  resources :projects, constraints: { id: /.*/ }, defaults: {format: :html} do
    collection do
      post :lookup
    end
  end

  resources :lists, constraints: { id: /.*/ }, defaults: {format: :html}  do
    collection do
      get :markdown, defaults: { format: :text }
    end
  end

  resources :topics, only: [:index, :show] do
    collection do
      get :suggestions
    end
  end
  
  resources :exports, only: [:index], path: 'open-data'

  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unprocessable'
  get '/500', to: 'errors#internal'

  root "lists#index"
end
