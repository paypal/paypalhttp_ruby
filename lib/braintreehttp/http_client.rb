require 'ostruct'
require 'net/http'
require 'date'

module BraintreeHttp

  LINE_FEED = "\r\n"

  class HttpClient
    attr_accessor :environment

    def initialize(environment)
      @environment = environment
      @injectors = []
      @encoder = Encoder.new
    end

    def user_agent
      "BraintreeHttp-Ruby HTTP/1.1"
    end

    def add_injector(&block)
      @injectors << block
    end

    def has_body(request)
      request.respond_to?(:body) and request.body
    end

    def execute(request)
      if !request.headers
        request.headers = {}
      end

      @injectors.each do |injector|
        injector.call(request)
      end

      if !request.headers["User-Agent"] || request.headers["User-Agent"] == "Ruby"
        request.headers["User-Agent"] = user_agent
      end

      httpRequest = Net::HTTPGenericRequest.new(request.verb, true, true, request.path, request.headers)

      content_type = request.headers["Content-Type"]
      if content_type && content_type.start_with?("multipart/")
        boundary = DateTime.now.strftime("%Q")
        httpRequest.set_content_type("multipart/form-data; boundary=#{boundary}")

        form_params = []
        request.body.each do |k, v|
          if v.is_a? File
            form_params.push(_add_file_part(k, v))
          else
            form_params.push(_add_form_field(k, v))
          end
        end

        httpRequest.body = form_params.collect {|p| "--" + boundary + "#{LINE_FEED}" + p}.join("") + "--" + boundary + "--"
      elsif has_body(request)
        if request.body.is_a? String
          httpRequest.body = request.body
        else
          httpRequest.body = serialize_request(request)
        end
      end

      uri = URI(@environment.base_url)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        _parse_response(http.request(httpRequest))
      end
    end

    def serialize_request(request)
      @encoder.serialize_request(request)
    end

    def deserialize_response(response_body, headers)
      @encoder.deserialize_response(response_body, headers)
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

    def _parse_response(response)
      status_code = response.code.to_i

      result = response.body
      headers = response.to_hash
      if result && !result.empty?
        deserialized = deserialize_response(response.body, headers)
        if deserialized.is_a? String
          result = deserialized
        else
          result = OpenStruct.new(deserialized)
        end
      else
        result = nil
      end

      obj = OpenStruct.new({
        :status_code => status_code,
        :result => result,
        :headers => response.to_hash,
      })

      if status_code >= 200 and status_code < 300
        return obj
      elsif
        raise HttpError.new(obj.status_code, obj.result, obj.headers)
      end
    end
  end
end
