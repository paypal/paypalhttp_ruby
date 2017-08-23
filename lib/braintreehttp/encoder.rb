require 'json'

module BraintreeHttp

  class Encoder
    def initialize
      @encoders = [Json.new, Text.new]
    end

    def serialize_request(req)
      raise UnsupportedEncodingError.new('HttpRequest did not have Content-Type header set') unless req.headers && (req.headers['content-type'] || req.headers['Content-Type'])

      content_type = req.headers['content-type'] || req.headers['Content-Type']
      content_type = content_type.first if content_type.kind_of?(Array)

      enc = _encoder(content_type)
      raise UnsupportedEncodingError.new("Unable to serialize request with Content-Type #{content_type}. Supported encodings are #{supported_encodings}") unless enc

      enc.encode(req.body)
    end

    def deserialize_response(resp, headers)
      raise UnsupportedEncodingError.new('HttpResponse did not have Content-Type header set') unless headers && (headers['content-type'] || headers['Content-Type'])

      content_type = headers['content-type'] || headers['Content-Type']
      content_type = content_type.first if content_type.kind_of?(Array)

      enc = _encoder(content_type)
      raise UnsupportedEncodingError.new("Unable to deserialize response with Content-Type #{content_type}. Supported decodings are #{supported_encodings}") unless enc

      enc.decode(resp)
    end

    def supported_encodings
      @encoders.map { |enc| enc.content_type.inspect }
    end

    def _encoder(content_type)
      idx = @encoders.index { |enc| enc.content_type.match(content_type) }

      @encoders[idx] if idx
    end
  end

  class Json

    def encode(body)
      JSON.generate(body)
    end

    def decode(body)
      JSON.parse(body)
    end

    def content_type
      /^application\/json$/
    end
  end

  class Text

    def encode(body)
      body.to_s
    end

    def decode(body)
      body.to_s
    end

    def content_type
      /^text\/.*/
    end
  end
end
