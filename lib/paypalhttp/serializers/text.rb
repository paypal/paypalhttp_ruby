module PayPalHttp
  class Text
    def encode(request)
      request.body.to_s
    end

    def decode(body)
      body.to_s
    end

    def content_type
      /text\/.*/
    end
  end
end
