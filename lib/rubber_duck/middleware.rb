require "rack/utils"

module RubberDuck
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      
      # Debug logging
      Rails.logger.info "RubberDuck: status=#{status}, content_type=#{headers['Content-Type']}, dev=#{Rails.env.development?}, enabled=#{RubberDuck.configuration.enabled}"
      
      # Only intercept in development mode
      if should_inject?(env, status, headers)
        Rails.logger.info "RubberDuck: Replacing response with custom error page"
        return build_error_response(env, status, headers, response)
      end
      
      [ status, headers, response ]
    rescue => e
      # Never break the app if our middleware fails
      Rails.logger.error("RubberDuck middleware error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      [ status, headers, response ]
    end

    private

    def should_inject?(env, status, headers)
      # Check if this is an error response
      return false unless Rails.env.development?
      return false unless RubberDuck.configuration.enabled
      return false unless status >= 400
      true
    end

    def build_error_response(env, status, headers, response)
      # Close the original response if it's closable
      response.close if response.respond_to?(:close)
      
      exception = env["action_dispatch.exception"]
      body = render_full_page_helper(exception, env, status)
      
      #
      Rails.logger.info "RubberDuck: Generated body size: #{body.bytesize}"
      Rails.logger.info "RubberDuck: Generated body snippet: #{body[0..200]}"
      #

      headers["Content-Type"] = "text/html; charset=utf-8"
      headers["Content-Length"] = body.bytesize.to_s
      headers["X-RubberDuck-Handled"] = "true"
      
      [status, headers, [body]]
    end

    def render_full_page_helper(exception, env, status)
      # This method will now generate a full HTML page
      # and include the existing render_helper logic within it.
      # The old render_helper will be inlined and modified here.
      logs = capture_logs
      error_data_script = if exception
        backtrace = exception.backtrace&.first(10) || []
        <<~JS
          const errorData = {
            exception: #{exception.message.to_json},
            backtrace: #{backtrace.to_json},
            logs: #{logs.to_json}
          };
        JS
      else
        path = env["PATH_INFO"]
        <<~JS
          const errorData = {
            status: #{status},
            path: #{path.to_json},
            logs: #{logs.to_json}
          };
        JS
      end

      error_title = Rack::Utils.escape_html(exception ? "#{exception.class}: #{exception.message}" : "HTTP Status #{status} for #{env['PATH_INFO']}")
      
      # The full HTML page
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>RubberDuck Debugger</title>
          <style>
            body { font-family: system-ui, sans-serif; background-color: #f9fafb; color: #1f2937; margin: 0; }
            .container { max-width: 800px; margin: 40px auto; padding: 20px; background: white; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
            h1 { font-size: 24px; color: #dc2626; }
            pre { background-color: #f3f4f6; padding: 16px; border-radius: 6px; white-space: pre-wrap; word-wrap: break-word; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Error Encountered</h1>
            <pre>#{error_title}</pre>
            <p>Use the RubberDuck button below to get help from AI.</p>
          </div>

          <div id="rubber-duck-container" style="position: fixed; bottom: 20px; right: 20px; z-index: 10000;">
            <button id="rubber-duck-button" style="background: #4F46E5; color: white; border: none; padding: 12px 24px; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
              🦆 Ask AI About This Error
            </button>
            <div id="rubber-duck-modal" style="display: none; position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 24px; border-radius: 12px; box-shadow: 0 20px 25px rgba(0,0,0,0.2); max-width: 600px; max-height: 80vh; overflow-y: auto; z-index: 10001;">
              <h3 style="margin: 0 0 16px 0; color: #1F2937;">AI Analysis</h3>
              <div id="rubber-duck-content" style="color: #4B5563; line-height: 1.6;">Analyzing...</div>
              <button id="rubber-duck-close" style="margin-top: 16px; background: #E5E7EB; color: #374151; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer;">Close</button>
            </div>
            <div id="rubber-duck-overlay" style="display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 10000;"></div>
          </div>
          <script>
            (function() {
              const button = document.getElementById('rubber-duck-button');
              const modal = document.getElementById('rubber-duck-modal');
              const overlay = document.getElementById('rubber-duck-overlay');
              const closeBtn = document.getElementById('rubber-duck-close');
              const content = document.getElementById('rubber-duck-content');
              #{error_data_script}
              button.addEventListener('click', async () => {
                modal.style.display = 'block';
                overlay.style.display = 'block';
                content.innerHTML = 'Analyzing error... This may take a few seconds.';
                try {
                  const response = await fetch('/rubber_duck/analyze_error', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(errorData)
                  });
                  const result = await response.json();
                  if (result.success) {
                    content.innerHTML = '<pre style="white-space: pre-wrap; font-family: system-ui;">' + result.response + '</pre>';
                  } else {
                    content.innerHTML = '<span style="color: #DC2626;">Error: ' + (result.error || 'Unknown error') + '</span>';
                  }
                } catch (error) {
                  content.innerHTML = '<span style="color: #DC2626;">Failed to connect: ' + error.message + '</span>';
                }
              });
              function closeModal() {
                modal.style.display = 'none';
                overlay.style.display = 'none';
              }
              closeBtn.addEventListener('click', closeModal);
              overlay.addEventListener('click', closeModal);
            })();
          </script>
        </body>
        </html>
      HTML
    end

    def capture_logs
      log_file = Rails.root.join("log", "development.log")
      return "Logs not available" unless File.exist?(log_file)
      lines = File.readlines(log_file).last(RubberDuck.configuration.log_lines)
      lines.join
    rescue => e
      "Error reading logs: #{e.message}"
    end
  end
end
