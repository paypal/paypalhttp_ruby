module BraintreeHttp
  class ServiceIOError < IOError
    attr_accessor :status_code, :data, :headers
    def initialize(status_code, data, headers)
      @status_code = status_code
      @data = data
      @headers = headers
    end
  end
end
