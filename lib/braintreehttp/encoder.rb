require 'json'
require 'uri'

module BraintreeHttp
  class Encoder
    def initialize
      @encoders = [Json.new, Text.new, Multipart.new, FormEncoded.new]
    end

    def serialize_request(req)
      raise UnsupportedEncodingError.new('HttpRequest did not have Content-Type header set') unless req.headers && (req.headers['content-type'] || req.headers['Content-Type'])

      content_type = req.headers['content-type'] || req.headers['Content-Type']
      content_type = content_type.first if content_type.kind_of?(Array)

      enc = _encoder(content_type)
      raise UnsupportedEncodingError.new("Unable to serialize request with Content-Type #{content_type}. Supported encodings are #{supported_encodings}") unless enc

      enc.encode(req)
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
    def encode(request)
      JSON.generate(request.body)
    end

    def decode(body)
      JSON.parse(body)
    end

    def content_type
      /^application\/json$/
    end
  end

  class Text
    def encode(request)
      request.body.to_s
    end

    def decode(body)
      body.to_s
    end

    def content_type
      /^text\/.*/
    end
  end

  class FormEncoded
    def encode(request)
      encoded_params = []
      request.body.each do |k, v|
        encoded_params.push("#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}")
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

  class Multipart
    def encode(request)
      boundary = DateTime.now.strftime("%Q")
      request.headers["Content-Type"] = "multipart/form-data; boundary=#{boundary}"

      form_params = []
      request.body.each do |k, v|
        if v.is_a? File
          form_params.push(_add_file_part(k, v))
        else
          form_params.push(_add_form_field(k, v))
        end
      end

      form_params.collect {|p| "--" + boundary + "#{LINE_FEED}" + p}.join("") + "--" + boundary + "--"
    end

    def decode(body)
      raise UnsupportedEncodingError.new("Multipart does not support deserialization")
    end

    def content_type
      /^multipart\/.*/
    end

    def _add_form_field(key, value)
      return "Content-Disposition: form-data; name=\"#{key}\"#{LINE_FEED}#{LINE_FEED}#{value}#{LINE_FEED}"
    end

    def _add_file_part(key, file)
      mime_type = _mime_type_for_file_name(file.path)
      return "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{File.basename(file.path)}\"#{LINE_FEED}" +
        "Content-Type: #{mime_type}#{LINE_FEED}#{LINE_FEED}#{file.read}#{LINE_FEED}"
    end

    def _mime_type_for_file_name(filename)
      file_extension = File.extname(filename).strip.downcase[1..-1]
      if file_extension == "jpeg" || file_extension == "jpg"
        return "image/jpeg"
      elsif file_extension == "png"
        return "image/png"
      elsif file_extension == "pdf"
        return "application/pdf"
      else
        return "application/octet-stream"
      end
    end
  end
end
