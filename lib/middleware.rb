module RailsAiDebugger
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      
      # Only inject on error pages in development
      if status == 500 && RailsAiDebugger.enabled?
        body = inject_debugger_ui(body, env)
      end
      
      [status, headers, body]
    end

    private

    def inject_debugger_ui(body, env)
      # Extract error info from env['action_dispatch.exception']
      # Inject button + JS before </body>
    end
  end
end