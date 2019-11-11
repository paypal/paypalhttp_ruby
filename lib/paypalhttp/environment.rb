module PayPalHttp
  class Environment
    attr_accessor :base_url
    def initialize(base_url)
      @base_url = base_url
    end
  end
end

