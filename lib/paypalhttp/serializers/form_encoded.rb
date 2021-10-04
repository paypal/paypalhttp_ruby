require 'uri'

module PayPalHttp
  class FormEncoded
    def encode(request)
      URI.encode_www_form(request.body)
    end

    def decode(body)
      raise UnsupportedEncodingError.new("FormEncoded does not support deserialization")
    end

    def content_type
      /^application\/x-www-form-urlencoded/
    end
  end
end
