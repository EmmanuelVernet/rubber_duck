require_relative "lib/rubber_duck/version"

Gem::Specification.new do |spec|
  spec.name        = "rubber_duck"
  spec.version     = RubberDuck::VERSION
  spec.authors     = [ "Emmanuel Vernet" ]
  spec.email       = [ "vernet.emmanuel@gmail.com" ]
  spec.homepage    = "https://github.com/EmmanuelVernet/rubber_duck"
  spec.summary     = "RubberDuck is a Developer error helper gem to help you analyze errors with AI in Rails"
  spec.description = "This gem allows the Rails developer to avoid switching context from Rails error pages during development. When getting an error, you can send the error and logs to an AI model of your choice and get a response to help you understand or pin point the issue while avoiding copy pasting code or logs into an external AI window. Perfect for those who prefer to code with minimal AI presence in their editor of choice!"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = "https://github.com/EmmanuelVernet/rubber_duck"
  spec.metadata["source_code_uri"] = "https://github.com/EmmanuelVernet/rubber_duck"
  spec.metadata["changelog_uri"] = "https://github.com/EmmanuelVernet/rubber_duck/releases"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.2.1"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "dotenv-rails"
end
