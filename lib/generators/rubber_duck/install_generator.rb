require "rails/generators"

module RubberDuck
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

			def create_initializer_file
				create_file "config/initializers/rubber_duck.rb", <<~CONTENT
					RubberDuck.configure do |config|
						# Get your API key from https://platform.openai.com
						config.openai_api_key = ENV["OPENAI_API_KEY"]
					
						# Model to use
						config.model = "gpt-5-nano"
					
						# Enable/disable the helper
						config.enabled = true
					
						# Number of log lines to send to AI for context
						config.log_lines = 50
					end
				CONTENT
			end

			def add_route
				say "Adding engine mount point to routes.rb", :green
				route "mount RubberDuck::Engine => '/rubber_duck'"
			end

			def show_instructions
				say "\n✅ RubberDuck installed!", :green
				say "\nNext steps:"
				say "  1. Add OPENAI_API_KEY to your .env file"
				say "  2. Restart your Rails server"
				say "  3. Trigger an error and look for the 'Ask AI' button\n"
			end
    end
  end
end
