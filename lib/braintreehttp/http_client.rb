require 'json'
require 'ostruct'

module BraintreeHttp

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
      @injectors.each do |injector|
        injector.inject(request)
      end

      if !request["User-Agent"] || request["User-Agent"] == "Ruby"
        request["User-Agent"] = user_agent
      end
      
      if request.body
        request.body = serializeRequest(request)
      end
      
      uri = URI(@environment.base_url)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        _parse_response(http.request(request))
      end
    end
    
    def serializeRequest(request)
      request.body
    end
    
    def deserializeResponse(responseBody, headers)
      responseBody
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
