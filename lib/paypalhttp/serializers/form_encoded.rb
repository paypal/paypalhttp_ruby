require 'uri'

module PayPalHttp
  class FormEncoded
    def encode(request)
      encoded_params = []
      request.body.each do |k, v|
        encoded_params.push("#{escape(k)}=#{escape(v)}")
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
    
    def escape(value)
      URI.encode_www_form_component(value.to_s).gsub('+', '%20')
    end
  end
end
