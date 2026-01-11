require "rack/utils"
require "erb"

module RubberDuck
  class Middleware
    def initialize(app)
      @app = app
      @model_name = RubberDuck.configuration.model
    end

    def call(env)
      status, headers, response = @app.call(env)

      # Debug logging
      # Rails.logger.info "RubberDuck: status=#{status}, content_type=#{headers['Content-Type']}, dev=#{Rails.env.development?}, enabled=#{RubberDuck.configuration.enabled}"

      # Only intercept in development mode
      if should_inject?(env, status, headers)
        # Rails.logger.info "RubberDuck: Replacing response with custom error page"
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

      # ONLY inject if request for HTML
      # accept_header = env["HTTP_ACCEPT"].to_s
      # return false unless accept_header.include?("text/html")

      # Ignore specific background noise
      # path = env["PATH_INFO"].to_s
      # return false if path.match?(/\.(ico|json|map|png|jpg|js|css)$/)

      true
    end

    def inject_button_response(env, status, headers, response)
      # Read original response body
      original_body = ""
      response.each { |part| original_body << part }
      response.close if response.respond_to?(:close)

      # Rails.logger.info "RubberDuck: Original body size: #{original_body.bytesize}"
      # Rails.logger.info "RubberDuck: Has </body>?: #{original_body.include?('</body>')}"

      # Don't inject if not HTML
      unless original_body.include?('<html') || original_body.include?('</body>')
        # Rails.logger.info "RubberDuck: Not HTML, skipping injection"
        return [ status, headers, [ original_body ] ]
      end

      exception = env["action_dispatch.exception"]
      modified_body = inject_button_into_html(original_body, exception, env, status)

      # Rails.logger.info "RubberDuck: Modified body size: #{modified_body.bytesize}"
      # Rails.logger.info "RubberDuck: Button injected?: #{modified_body.include?('rubber-duck-button')}"

      headers["Content-Type"] = "text/html; charset=utf-8"
      headers["Content-Length"] = modified_body.bytesize.to_s
      headers["X-RubberDuck-Handled"] = "true"

      [ status, headers, [ modified_body ] ]
    end

    def inject_button_into_html(html, exception, env, status)
      gem_path = Gem.loaded_specs['rubber_duck'].full_gem_path
      # button_html = ApplicationController.render(
      #   partial: "rubber_duck/button",
      #   locals: {
      #     model_name: @model_name
      #   }
      # )
      partial_path = File.join(gem_path, 'app/views/rubber_duck/_button.html.erb')
      partial_content = File.read(partial_path)
      button_html = ERB.new(partial_content).result(binding)

      logs = capture_logs
      error_data_script = build_error_data_script(exception, env, status, logs)

      # Load JS from file
      modal_js = File.read(File.join(gem_path, 'app/assets/javascripts/rubber_duck/modal.js'))

      injection = <<~HTML
        <div>
          #{button_html}
        </div>
        <script>
         #{error_data_script}
         #{modal_js}
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
      # Prepare the data object in Ruby
      data = if exception
        {
          exception: exception.message,
          backtrace: exception.backtrace&.first(10) || [],
          logs: logs
        }
      else
        {
          status: status,
          path: env["PATH_INFO"],
          logs: logs
        }
      end

      # Inject it as a single, globally accessible JSON object
      <<~JS
        window.errorData = #{data.to_json};
      JS
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
