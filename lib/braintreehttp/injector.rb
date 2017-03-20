module BraintreeHttp
  class Injector
    def inject(request)
      raise NotImplementedError, "Injectors must implement inject"
    end
  end
end
