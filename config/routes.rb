RubberDuck::Engine.routes.draw do
	post "/analyze", to: "errors#analyze"
end
