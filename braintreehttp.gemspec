$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = "braintreehttp"
  s.summary = "BraintreeHttp Client Library"
  s.description = "Used for generated API clients"
  s.version = "0.1.5"
  s.license = "MIT"
  s.author = "Braintree"
  s.email = "code@getbraintree.com"
  s.homepage = "http://www.braintreepayments.com/"
  s.rubyforge_project = "braintreehttp"
  s.has_rdoc = false
  s.files = Dir.glob ["lib/**/*.{rb}", "spec/**/*", "*.gemspec"]
end
