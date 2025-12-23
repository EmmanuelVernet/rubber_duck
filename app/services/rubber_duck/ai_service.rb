require "faraday"
require "json"

module RubberDuck
  class AiService
    class << self
      def analyze_error(exception_message:, backtrace:, logs:)
        return { error: "No API key configured" } unless RubberDuck.configuration.openai_api_key
        prompt = build_prompt(exception_message, backtrace, logs)
        
        begin
          response = call_openai(prompt)
          { success: true, response: response }
        rescue => e
          { success: false, error: e.message }
        end
      end

      def analyze_http_error(status:, path:, logs:)
        return { error: "No API key configured" } unless RubberDuck.configuration.openai_api_key
        prompt = build_http_error_prompt(status, path, logs)
        
        begin
          response = call_openai(prompt)
          { success: true, response: response }
        rescue => e
          { success: false, error: e.message }
        end
      end

      private

      def build_http_error_prompt(status, path, logs)
        <<~PROMPT
          You are a helpful Ruby on Rails debugging assistant. A developer encountered an HTTP error.
          STATUS: #{status}
          PATH: #{path}
          RECENT LOGS:
          #{logs || "No logs available"}
          Please:
          1. Explain what this HTTP status code means in the context of a Rails application.
          2. Identify the likely cause for this error on this specific path.
          3. Suggest specific areas to investigate and potential fixes.
          
          Keep your response concise and actionable.
        PROMPT
      end
			
      def build_prompt(exception, backtrace, logs)
        <<~PROMPT
          You are a helpful Ruby on Rails debugging assistant. A developer encountered this error:
          ERROR: #{exception}
          BACKTRACE:
          #{backtrace&.first(10)&.join("\n") || "No backtrace available"}
          RECENT LOGS:
          #{logs || "No logs available"}
          Please:
          1. Explain what this error means
          2. Identify the likely cause
          3. Suggest specific fixes
          
          Keep your response concise and actionable.
        PROMPT
      end

      def call_openai(prompt)
        conn = Faraday.new(url: "https://api.openai.com") do |f|
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
        end
        response = conn.post("/v1/chat/completions") do |req|
          req.headers["Authorization"] = "Bearer #{RubberDuck.configuration.openai_api_key}"
          req.headers["Content-Type"] = "application/json"
          req.body = {
            model: RubberDuck.configuration.model,
            messages: [
              { role: "system", content: "You are a Rails debugging expert." },
              { role: "user", content: prompt }
            ],
            temperature: 1,
            max_completion_tokens: 3000
          }
        end
        ## debug output
        puts "======> OpenAI Response Body: #{response.body.inspect}"
        ##
        response.body.dig("choices", 0, "message", "content")
      end
			
    end
  end
end