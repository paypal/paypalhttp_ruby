module PayPalHttp
  class Multipart

    LINE_FEED = "\r\n"

    def encode(request)
      boundary = DateTime.now.strftime("%Q")
      request.headers["content-type"] = "#{request.headers['content-type']}; boundary=#{boundary}"

      form_params = []
      value_params = []
      file_params = []

      request.body.each do |k, v|
        if v.is_a? File
          file_params.push(_add_file_part(k, v))
        elsif v.is_a? FormPart
          value_params.push(_add_form_part(k, v))
        else
          value_params.push(_add_form_field(k, v))
        end
      end

      form_params = value_params + file_params
      form_params.collect {|p| "--" + boundary + "#{LINE_FEED}" + p}.join("") + "--" + boundary + "--"
    end

    def decode(body)
      raise UnsupportedEncodingError.new("Multipart does not support deserialization")
    end

    def content_type
      /multipart\/.*/
    end

    def _add_form_field(key, value)
      return "Content-Disposition: form-data; name=\"#{key}\"#{LINE_FEED}#{LINE_FEED}#{value}#{LINE_FEED}"
    end

    def _add_form_part(key, form_part)
      retValue = "Content-Disposition: form-data; name=\"#{key}\""
      formatted_headers = format_headers(form_part.headers)
      if formatted_headers["content-type"] == "application/json"
        retValue += "; filename=\"#{key}.json\""
      end
      retValue += "#{LINE_FEED}"

      form_part.headers.each do |key, value|
        retValue += "#{key}: #{value}#{LINE_FEED}"
      end

      retValue += "#{LINE_FEED}"

      if formatted_headers["content-type"]
        retValue += Encoder.new().serialize_request(OpenStruct.new({
          :verb => 'POST',
          :path => '/',
          :headers => formatted_headers,
          :body => form_part.value
        }))
      else
        retValue += form_part.value
      end

      retValue += "#{LINE_FEED}"

      return retValue
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
      elsif file_extension == "gif"
        return "image/gif"
      elsif file_extension == "png"
        return "image/png"
      elsif file_extension == "pdf"
        return "application/pdf"
      else
        return "application/octet-stream"
      end
    end

    def format_headers(headers)
      formatted_headers = {}
      headers.each do |key, value|
        formatted_headers[key.downcase] = value
      end
      formatted_headers
    end
  end
end
