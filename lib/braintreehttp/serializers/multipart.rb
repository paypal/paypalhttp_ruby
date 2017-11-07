module BraintreeHttp
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
      /multipart\/.*/
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
