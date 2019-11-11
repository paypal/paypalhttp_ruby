module PayPalHttp
  class FormPart
    attr_accessor :value, :headers

    def initialize(value, headers)
      @value = value
      @headers = {}

      headers.each do |key, value|
        @headers[key.to_s.downcase.split('-').map { |word| "#{word[0].upcase}#{word[1..-1]}" }.join("-")] = value
      end
    end
  end
end
