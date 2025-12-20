module RubberDuck
  class Engine < ::Rails::Engine
    isolate_namespace RubberDuck

    # Middleware injects UI on error pages
    initializer "rubber_duck.middleware" do |app|
      app.middleware.use RubberDuck::Middleware if Rails.env.development?
    end
  end
end
