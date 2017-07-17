require 'json'
require 'ostruct'

module BraintreeHttp

  LINE_FEED = "\r\n"

  class HttpClient
    attr_accessor :environment

    def initialize(environment)
      @environment = environment
      @injectors = []
    end

    def user_agent
      "BraintreeHttp-Ruby HTTP/1.1"
    end

    def add_injector(inj)
      @injectors << inj
    end

    def execute(request)
      if !request.headers
        request.headers = {}
      end

      @injectors.each do |injector|
        injector.inject(request)
      end

      if !request.headers["User-Agent"] || request.headers["User-Agent"] == "Ruby"
        request.headers["User-Agent"] = user_agent
      end

      httpRequest = Net::HTTPGenericRequest.new(request.verb, true, true, request.path, request.headers)

      if request.body && !request.file
        if request.body.is_a? String
          httpRequest.body = request.body
        else
          httpRequest.body = serializeRequest(request)
				end
			end

			if request.file # encode with multipart/form-data
				boundary = DateTime.now.strftime("%Q")
				httpRequest.set_content_type("multipart/form-data; boundary=#{boundary}")

        form_params = []
        if request.body
          request.body.each do |k, v|
            form_params.push(_add_form_field(k, v))
          end
        end
				form_params.push(_add_file_part("file", request.file))
        httpRequest.body = form_params.collect {|p| "--" + boundary + "#{LINE_FEED}" + p}.join("") + "--" + boundary + "--"
			end

			uri = URI(@environment.base_url)
			Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        _parse_response(http.request(httpRequest))
      end
    end

    def serializeRequest(request)
      request.body
    end

		def deserializeResponse(responseBody, headers)
			responseBody
		end

		def _add_form_field(key, value)
			return "Content-Disposition: form-data; name=\"#{key}\"#{LINE_FEED}#{LINE_FEED}#{value}#{LINE_FEED}"
		end

		def _add_file_part(key, file)
			mime_type = _mime_type_for_file_name(file.path)
			return "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{file.path}\"#{LINE_FEED}" +
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
      status_code = response.code
      body = response.body

      obj = OpenStruct.new({
        :status_code => status_code,
        :result => deserializeResponse(response.body, response.to_hash),
        :headers => response.to_hash,
      })

      if status_code.to_i >= 200 and status_code.to_i < 300
        return obj
      elsif
        raise ServiceIOError.new(obj.status_code, obj.result, obj.headers)
      end
    end
  end
end
