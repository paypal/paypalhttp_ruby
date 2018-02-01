require 'ostruct'
require 'net/http'
require 'date'

module BraintreeHttp

  class HttpClient
    attr_accessor :environment, :encoder

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

      if !request.headers["User-Agent"] || request.headers["User-Agent"] == "Ruby"
        request.headers["User-Agent"] = user_agent
      end

      body = nil
      if has_body(request)
        body = @encoder.serialize_request(request)
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
        deserialized = @encoder.deserialize_response(response.body, headers)
        if deserialized.is_a?(String) || deserialized.is_a?(Array)
          result = deserialized
        else
          result = _parse_hash(deserialized)
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

    def _parse_hash(hash)
      obj = OpenStruct.new()

      hash.each do |k, v|
        if v.is_a?(Hash)
          obj[k] = _parse_hash(v)
        else
          obj[k] = v
        end
      end

      obj
    end
  end
end
