require_relative "lib/pinnable/version"

Gem::Specification.new do |spec|
  spec.name        = "pinnable"
  spec.version     = Pinnable::VERSION
  spec.authors     = [ "Vlad Mehakovic" ]
  spec.email       = [ "701194+vladiim@users.noreply.github.com" ]
  spec.homepage    = "https://github.com/vladiim/pinnable"
  spec.summary     = "Click any element, pin a comment, work it like a task list."
  spec.description = "A host-agnostic, mountable Rails engine for in-app visual feedback: " \
    "enable it for some users, toggle comment mode, click any DOM element to leave a note that " \
    "re-anchors on reload and is tracked open -> resolved. Hotwire/Stimulus, any database."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0", "< 9"
end
