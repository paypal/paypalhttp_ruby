require 'json'
require 'ostruct'

module BraintreeHttp

  class DefaultHttpClient
    def initialize
      @injectors = []
    end

    def user_agent
      return "BraintreeHttp-Ruby HTTP/1.1"
    end

    def add_injector(inj)
      @injectors << inj
    end

    def execute(request)
      @injectors.each do |injector|
        injector.inject(request)
      end

      if !request["User-Agent"]
        request["User-Agent"] = user_agent
      end

      Net::HTTP.new(request.uri.host).start do |http|
        parse_response(http.request(request))
      end
    end

    def parse_response(response)
      status_code = response.code
      body = response.body
      begin
        body = OpenStruct.new(JSON.parse(response.body))
      rescue
      end

      obj = OpenStruct.new({
        :status_code => status_code,
        :result => body,
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
