module BraintreeHttp

  class Injector
    def inject(request)
      raise NotImplementedError, "Injectors must implement inject"
    end
  end

  class AuthInjector < Injector
    attr_accessor :environment, :refresh_token, :access_token, :token_service, :client_id, :client_secret, :base_url
    def initialize(environment, refresh_token=nil)
      @environment = environment
      @refresh_token = refresh_token
    end

    def inject(request)
      token = nil
      if self.access_token
        token = self.access_token
      elsif
        #token = self.token_service.fetch_access_token(refresh_token=self.refresh_token)
        self.access_token = token
      end
      request.headers["Authorization"] = "Bearer " + token.access_token
      return request
    end
  end
end
