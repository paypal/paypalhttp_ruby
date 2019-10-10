module PayPalHttp
  class HttpError < IOError
    attr_accessor :status_code, :result, :headers
    def initialize(status_code, result, headers)
      @status_code = status_code
      @result = result
      @headers = headers
    end
  end

  class UnsupportedEncodingError < IOError
    def initialize(msg)
      super(msg)
    end
  end
end
