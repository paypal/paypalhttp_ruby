require_relative './lib/paypalhttp/version'

$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = "paypalhttp"
  s.summary = "PayPalHttp Client Library"
  s.description = "Used for generated API clients"
  s.version = VERSION
  s.license = "MIT"
  s.author = "PayPal"
  s.rubyforge_project = "paypalhttp"
  s.has_rdoc = false
  s.files = Dir.glob ["lib/**/*.{rb}", "spec/**/*", "*.gemspec"]
end
