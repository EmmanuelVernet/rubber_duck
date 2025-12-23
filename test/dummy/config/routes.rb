Rails.application.routes.draw do
  mount RubberDuck::Engine => '/rubber_duck'
  # mount RubberDuck::Engine => "/rubber_duck"
  post "/analyze_error", to: "errors#analyze"
end
