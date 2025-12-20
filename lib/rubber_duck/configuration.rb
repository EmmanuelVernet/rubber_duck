module RubberDuck
  class Configuration
    attr_accessor :openai_api_key, :model, :enabled, :log_lines
    def initialize
      @openai_api_key = nil
      @model = "gpt-5-nano"
      @enabled = true
      @log_lines = 50
    end
  end
  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    def configure
      yield(configuration)
    end
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end