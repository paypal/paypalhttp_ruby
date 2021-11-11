require 'ostruct'
require 'net/http'
require 'date'

module PayPalHttp

  class HttpClient
    attr_accessor :environment, :encoder

    def initialize(environment)
      @environment = environment
      @injectors = []
      @encoder = Encoder.new
    end

    def user_agent
      "PayPalHttp-Ruby HTTP/1.1"
    end

    def add_injector(&block)
      @injectors << block
    end

    def has_body(request)
      request.respond_to?(:body) and request.body
    end

    def format_headers(headers)
      headers.transform_keys(&:downcase)
    end

    def map_headers(raw_headers , formatted_headers)
      raw_headers.each do |key, value|
        if formatted_headers.key?(key.downcase) == true
          raw_headers[key] = formatted_headers[key.downcase]
        end
      end
      raw_headers
    end

    def execute(req)
      headers = req.headers || {}

      request = OpenStruct.new({
        :verb => req.verb,
        :path => req.path,
        :headers => headers.clone,
        :body => req.body,
      })

      if !request.headers
        request.headers = {}
      end

      @injectors.each do |injector|
        injector.call(request)
      end

      formatted_headers = format_headers(request.headers)
      if !formatted_headers["user-agent"] || formatted_headers["user-agent"] == "Ruby"
        request.headers["user-agent"] = user_agent
      end

      body = nil
      if has_body(request)
        raw_headers = request.headers
        request.headers = formatted_headers
        body = @encoder.serialize_request(request)
        request.headers = map_headers(raw_headers, request.headers)
      end

      http_request = Net::HTTPGenericRequest.new(request.verb, body != nil, true, request.path, request.headers)
      http_request.body = body

      uri = URI(@environment.base_url)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        _parse_response(http.request(http_request))
      end
    end

    def _parse_response(response)
      status_code = response.code.to_i

      result = response.body
      headers = response.to_hash
      if result && !result.empty?
        deserialized = @encoder.deserialize_response(response.body, format_headers(headers))
        if deserialized.is_a?(String) || deserialized.is_a?(Array)
          result = deserialized
        else
          result = _parse_values(deserialized)
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

    def _parse_values(values)
      obj = nil

      if values.is_a?(Array)
        obj = []
        values.each do |v|
          obj << _parse_values(v)
        end
      elsif values.is_a?(Hash)
        obj = OpenStruct.new()
        values.each do |k, v|
          obj[k] = _parse_values(v)
        end
      else
        obj = values
      end

      obj
    end
  end
end
