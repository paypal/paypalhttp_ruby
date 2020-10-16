require 'uri'

module PayPalHttp
  class FormEncoded
    def encode(request)
      encoded_params = []
      request.body.each do |k, v|
        encoded_params.push("#{encode_part(k)}=#{encode_part(v)}")
      end

      encoded_params.join("&")
    end

    def decode(body)
      raise UnsupportedEncodingError.new("FormEncoded does not support deserialization")
    end

    def content_type
      /^application\/x-www-form-urlencoded/
    end

    private

    def encode_part(part)
      URI.encode_www_form_component(part.to_s)
    end
  end
end
