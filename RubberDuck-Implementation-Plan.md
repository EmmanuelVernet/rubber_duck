# Problem Statement
Create a Rails gem that intercepts error pages in development and adds an AI-powered button that allows developers to get instant help with errors without leaving the error page or switching context to external AI tools.
# Current State
The rubber_duck gem is scaffolded as a Rails Engine with:
* Basic engine structure in lib/rubber_duck/engine.rb
* Install generator that creates an initializer
* Standard Rails engine app/ directory structure
* Empty routes configuration
The gemspec indicates Rails >= 8.0.2.1 as a dependency, and the description already outlines the goal: helping developers get error context with AI directly on Rails error pages.
# Proposed Changes
## 1. Configuration System
Create lib/rubber_duck/configuration.rb to handle:
* AI provider settings (OpenAI API key, model selection)
* Enable/disable flag (development only by default)
* Customizable prompt templates
* Log capture settings (number of lines, filtering)
Update lib/rubber_duck.rb to include configuration class methods (configure, configuration, reset_configuration).
## 2. Middleware for Error Interception
Create lib/rubber_duck/middleware.rb that:
* Intercepts exceptions in development mode
* Captures the exception, backtrace, and recent logs
* Injects JavaScript and HTML into the error page response
* Only activates when configuration is enabled and in development environment
## 3. AI Service Integration
Create app/services/rubber_duck/ai_service.rb to:
* Interface with OpenAI API (extensible for other providers)
* Format error context (exception message, backtrace, logs) into AI prompts
* Handle API requests and responses
* Include error handling for API failures
## 4. Controller and API Endpoint
Create app/controllers/rubber_duck/errors_controller.rb with:
* POST endpoint to receive error data from frontend
* Call AI service with error context
* Return AI response as JSON
* Include authentication/safety checks to prevent abuse
Update config/routes.rb to mount the errors endpoint.
## 5. Frontend Components
### JavaScript (app/assets/javascripts/rubber_duck/error_helper.js)
* Add "Ask AI" button to error pages
* Capture error details from DOM
* Make AJAX request to backend endpoint
* Display AI response in modal or expandable panel
* Show loading states and handle errors
### Styling (app/assets/stylesheets/rubber_duck/error_helper.css)
* Style the AI button to match Rails error page aesthetics
* Create modal/panel styling for AI responses
* Ensure responsive design
* Code syntax highlighting for AI responses
### View Partial (app/views/rubber_duck/_error_helper.html.erb)
* HTML structure for button and response container
* Inline critical CSS if needed
* Meta tags for CSRF protection
## 6. Log Capture Utility
Create lib/rubber_duck/log_capturer.rb to:
* Read recent lines from development.log
* Filter sensitive information
* Extract relevant context around error timestamp
* Handle missing or inaccessible log files gracefully
## 7. Engine Integration
Update lib/rubber_duck/engine.rb to:
* Register middleware in development environment
* Set up asset paths for JavaScript and CSS
* Configure autoload paths
* Add initializer to check for required configuration
## 8. Installation Generator Enhancement
Update lib/generators/rubber_duck/install_generator.rb to:
* Create more detailed initializer with all configuration options
* Add instructions for setting API key
* Optionally create .env entry
* Display post-install instructions
## 9. Dependencies
Update rubber_duck.gemspec to add:
* HTTP client gem (e.g., faraday or httparty) for API calls
* JSON parsing (already in Ruby stdlib)
## 10. Testing and Documentation
Update README.md with:
* Clear installation instructions
* Configuration examples
* Security considerations
* Troubleshooting guide
* Screenshots or GIFs of the feature in action
## Implementation Order
1. Configuration system (lib/rubber_duck/configuration.rb)
2. Log capturer utility (lib/rubber_duck/log_capturer.rb)
3. AI service (app/services/rubber_duck/ai_service.rb)
4. Controller and routes (app/controllers/rubber_duck/errors_controller.rb, config/routes.rb)
5. Frontend assets (JavaScript, CSS, view partial)
6. Middleware (lib/rubber_duck/middleware.rb)
7. Engine integration (lib/rubber_duck/engine.rb)
8. Generator updates (lib/generators/rubber_duck/install_generator.rb)
9. Dependencies (rubber_duck.gemspec)
10. Documentation (README.md)
## Key Technical Decisions
* **Development-only by default**: Middleware only activates in development to prevent production exposure
* **OpenAI as first provider**: Start with OpenAI API, design service layer for easy provider extension
* **Async UI**: Use JavaScript fetch API for non-blocking AI requests
* **CSRF protection**: Include Rails CSRF tokens in API requests
* **Error isolation**: Wrap all gem code in error handlers to prevent the gem itself from breaking the app
* **No database required**: Keep gem lightweight with no migrations or database dependencies
