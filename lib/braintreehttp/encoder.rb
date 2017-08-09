require 'json'

module BraintreeHttp

  class Encoder

    def serialize_request(req)
      raise UnsupportedEncodingError.new('HttpRequest did not have Content-Type header set') unless req.headers && (req.headers['content-type'] || req.headers['Content-Type'])

      content_type = req.headers['content-type'] || req.headers['Content-Type']
      raise UnsupportedEncodingError.new("Unable to serialize request with Content-Type #{content_type}. Supported encodings are #{supported_encodings}") unless content_type == 'application/json'

      JSON.generate(req.body)
    end

    def deserialize_response(resp, headers)
      raise UnsupportedEncodingError.new('HttpResponse did not have Content-Type header set') unless headers && (headers['content-type'] || headers['Content-Type'])

      content_type = headers['content-type'] || headers['Content-Type']
      raise UnsupportedEncodingError.new("Unable to deserialize response with Content-Type #{content_type}. Supported decodings are #{supported_decodings}") unless content_type.include? 'application/json'

      JSON.parse(resp)
    end

    def supported_encodings
      ['application/json']
    end

    def supported_decodings
      ['application/json']
    end
  end
end
