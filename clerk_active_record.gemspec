lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "clerk_active_record/version"

Gem::Specification.new do |spec|
  spec.name          = "clerk_active_record"
  spec.version     = ClerkActiveRecord::VERSION
  spec.authors     = ["Colin Sidoti", "Braden Sidoti"]
  spec.email       = ["hello@clerk.dev"]
  spec.summary     = "Configures Clerk models for ActiveRecord"
  spec.license     = "MIT"

  spec.files = Dir["{lib}/**/*", "LICENSE.txt", "README.md"]

  spec.add_dependency "activerecord", "~> 5.2.0"
  spec.add_dependency "pg"
end
