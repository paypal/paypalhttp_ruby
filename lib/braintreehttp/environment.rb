module BraintreeHttp

  class Environment
    attr_accessor :base_url
  end

  class PayPalEnvironment < Environment

    SANDBOX = "https://api.sandbox.paypal.com"
    PRODUCTION = "https://api.paypal.com"

    attr_accessor :client_id, :client_secret
    def initialize(client_id, client_secret, base_url)
      @client_id = client_id
      @client_secret = client_secret
      @base_url = base_url
    end
  end
end

