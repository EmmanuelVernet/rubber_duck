RubberDuck.configure do |config|
  # Get your API key from https://platform.openai.com
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  
  # Model to use (gpt-4o-mini is cheaper, gpt-4o is more capable)
  config.model = "gpt-4o-mini"
  
  # Enable/disable the helper (only works in development anyway)
  config.enabled = true
  
  # Number of log lines to send to AI for context
  config.log_lines = 50
end
