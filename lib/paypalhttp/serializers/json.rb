require 'json'

module PayPalHttp
  class Json
    def encode(request)
      JSON.generate(request.body)
    end

    def decode(body)
      JSON.parse(body)
    end

    def content_type
      /application\/json/
    end
  end
end
