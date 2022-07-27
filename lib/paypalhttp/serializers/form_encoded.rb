require 'uri'

module PayPalHttp
  class FormEncoded
    def initialize
      @parser = URI::Parser.new()
    end

    def encode(request)
      encoded_params = []
      request.body.each do |k, v|
        encoded_params.push("#{@parser.escape(k.to_s)}=#{@parser.escape(v.to_s)}")
      end

      encoded_params.join("&")
    end

    def decode(body)
      raise UnsupportedEncodingError.new("FormEncoded does not support deserialization")
    end

    def content_type
      /^application\/x-www-form-urlencoded/
    end
  end
end
