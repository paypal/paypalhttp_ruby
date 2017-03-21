require File.expand_path("../lib/your_gem/version", __FILE__)

Gem::Specification.new do |gem|
  s.name = "braintreehttp"
  s.summary = "BraintreeHttp Client Library"
  s.description = "Used for API clients"
  s.version = Braintree::Version::String
  s.license = "MIT"
  s.author = "Braintree"
  s.email = "code@getbraintree.com"
  s.homepage = "http://www.braintreepayments.com/"
  s.rubyforge_project = "braintreehttp"
  s.has_rdoc = false
  s.files = Dir.glob ["README.rdoc", "LICENSE", "lib/**/*.{rb,crt}", "spec/**/*", "*.gemspec"]
  s.add_dependency "builder", ">= 2.0.0"
end
