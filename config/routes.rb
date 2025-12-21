RubberDuck::Engine.routes.draw do
  post "/analyze_error", to: "errors#analyze"
end
