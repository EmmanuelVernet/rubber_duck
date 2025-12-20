require 'rails/generators'

module RubberDuck
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def create_initializer_file
        create_file "config/initializers/rubber_duck.rb", <<~CONTENT
          RubberDuck.configure do |config|
            # config.openai_api_key = ENV["OPENAI_API_KEY"]
            # config.model = "gpt-4"
          end
        CONTENT
      end
    end
  end
end