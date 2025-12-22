require "rubber_duck/middleware"
module RubberDuck
  class Engine < ::Rails::Engine
    isolate_namespace RubberDuck
    # config.app_middleware.use RubberDuck::Middleware
    config.app_middleware.insert_before ActionDispatch::ShowExceptions, RubberDuck::Middleware

    # Middleware injects UI on error pages
    # initializer "rubber_duck.middleware" do |app|
    #   app.middleware.use RubberDuck::Middleware if Rails.env.development?
    # end
  end
end
