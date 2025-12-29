require "rack/utils"

module RubberDuck
  class Middleware
    def initialize(app)
      @app = app
      @model_name = RubberDuck.configuration.model
    end

    def call(env)
      status, headers, response = @app.call(env)
      
      # Debug logging
      Rails.logger.info "RubberDuck: status=#{status}, content_type=#{headers['Content-Type']}, dev=#{Rails.env.development?}, enabled=#{RubberDuck.configuration.enabled}"
      
      # Only intercept in development mode
      if should_inject?(env, status, headers)
        Rails.logger.info "RubberDuck: Replacing response with custom error page"
        return inject_button_response(env, status, headers, response)
      end
      
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

    def inject_button_response(env, status, headers, response)
      # Read original response body
      original_body = ""
      response.each { |part| original_body << part }
      response.close if response.respond_to?(:close)
      
      Rails.logger.info "RubberDuck: Original body size: #{original_body.bytesize}"
      Rails.logger.info "RubberDuck: Has </body>?: #{original_body.include?('</body>')}"
      
      # Don't inject if not HTML
      unless original_body.include?('<html') || original_body.include?('</body>')
        Rails.logger.info "RubberDuck: Not HTML, skipping injection"
        return [status, headers, [original_body]]
      end
      
      exception = env["action_dispatch.exception"]
      modified_body = inject_button_into_html(original_body, exception, env, status)
      
      Rails.logger.info "RubberDuck: Modified body size: #{modified_body.bytesize}"
      Rails.logger.info "RubberDuck: Button injected?: #{modified_body.include?('rubber-duck-button')}"
      
      headers["Content-Type"] = "text/html; charset=utf-8"
      headers["Content-Length"] = modified_body.bytesize.to_s
      headers["X-RubberDuck-Handled"] = "true"
      
      [status, headers, [modified_body]]
    end

    def inject_button_into_html(html, exception, env, status)
      logs = capture_logs
      error_data_script = build_error_data_script(exception, env, status, logs)
      
      injection = <<~HTML
        <div id="rubber-duck-container" style="display: flex; margin-left: 20px;">
          <button id="rubber-duck-button" style="background: #8f9cc9; color: white; border: none; padding: 8px 16px; border-radius: 6px; font-size: 14px; font-weight: 600; cursor: pointer; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            🦆 RubberDuck
          </button>
          <div id="rubber-duck-modal" style="display: none; position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 24px; border-radius: 12px; box-shadow: 0 20px 25px rgba(0,0,0,0.2); max-width: 600px; max-height: 80vh; overflow-y: auto; z-index: 10001;">
            <h3 style="margin: 0 0 16px 0; color: #1F2937;">#{@model_name.capitalize} Analysis</h3>
            <div id="rubber-duck-content" style="color: #4B5563; line-height: 1.6;">Analyzing...</div>
            <button id="rubber-duck-close" style="margin-top: 16px; background: #E5E7EB; color: #374151; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer;">Close</button>
          </div>
          <div id="rubber-duck-overlay" style="display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 10000;"></div>
        </div>
        <script>
          // force align button in DOM 
          document.addEventListener("DOMContentLoaded", () => {
            const h1 = document.querySelector("h1")
            const duck = document.getElementById("rubber-duck-container")

            if (!h1 || !duck) return

            h1.style.display = "flex"
            h1.style.alignItems = "center"

            h1.appendChild(duck)
          });
          // create modal & API call
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
      HTML
      
      # Inject before </body> if exists, otherwise append
      if html =~ /<\/header>/i
        html.sub(/<\/header>/i, "#{injection}</header>")
      else
        html + injection
      end
    end

    def build_error_data_script(exception, env, status, logs)
      if exception
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
