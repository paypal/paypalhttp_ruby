require_relative "lib/braintreehttp.rb"
include BraintreeHttp
require 'net/http'

env = PayPalEnvironment.new("AYSq3RDGsmBLJE-otTkBtM-jBRd1TCQwFf9RGfwddNXWz0uFU9ztymylOhRS",
            "EGnHDxD_qRPdaLdZz8iCr8N7_MzF-YHPTkjs6NKYQvQSBngp4PTTVWkPZRbL",
            PayPalEnvironment::SANDBOX)

puts env.client_id
puts env.client_secret
puts env.base_url

inj = AuthInjector.new(env)
puts inj.environment

client = DefaultHttpClient.new
request = Net::HTTP::Get.new(URI('http://ip.jsontest.com/'))
resp = nil
begin
  resp = client.execute(request)
rescue => e
  resp = e
  puts resp.status_code
end

puts resp.inspect
