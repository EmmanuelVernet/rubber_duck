module RailsAiDebugger
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      
      if status == 500 && Rails.env.development?
        response = inject_ui(response, env)
      end
      
      [status, headers, response]
    end

    private

    def inject_ui(response, env)
      # TODO: inject button HTML before </body>
      response
    end
  end
end