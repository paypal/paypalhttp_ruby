require 'ostruct'

describe Encoder do

  describe 'serialize_request' do
    it 'serializes the request when content-type == application/json' do
      req = OpenStruct.new({
        :headers  => {
          "content-type" => "application/json"
        },
        :body => {
          "string" => "value",
          "number" => 1.23,
          "bool" => true,
          "array" => ["one", "two", "three"],
          "nested" => {
            "nested_string" => "nested_value",
            "nested_array" => [1,2,3]
          }
        }
      })

      expected = '{"string":"value","number":1.23,"bool":true,"array":["one","two","three"],"nested":{"nested_string":"nested_value","nested_array":[1,2,3]}}'

      expect(Encoder.new.serialize_request(req)).to eq(expected)
    end

    it 'serializes the request when content-type == text/*' do
      req = OpenStruct.new({
        :headers  => {
          "content-type" => "text/plain"
        },
        :body => "some text"
      })

      expect(Encoder.new.serialize_request(req)).to eq("some text")
    end

    it 'serializes the request when content-type == multipart/form-data' do
      http_client = HttpClient.new(@environment)
      file = File.new("README.md", "r")
      req = OpenStruct.new({
        :verb => "POST", 
        :path => "/v1/api", 
        :headers => {
          "Content-Type" => "multipart/form-data"
        },
        :body => {
          :key => "value",
          :another_key => 1013,
          :readme => file,
        }
      })

      serialized = Encoder.new.serialize_request(req)

      expect(serialized).to include("Content-Disposition: form-data; name=\"readme\"; filename=\"README.md\"")
      expect(serialized).to include("Content-Disposition: form-data; name=\"readme\"; filename=\"README.md\"")
      expect(serialized).to include("Content-Disposition: form-data; name=\"key\"")
      expect(serialized).to include("value")
      expect(serialized).to include("Content-Disposition: form-data; name=\"another_key\"")
      expect(serialized).to include("1013")
    end

    it 'throws when content-type is not application/json' do
      req = OpenStruct.new({
        :headers  => {
          "content-type" => "not application/json"
        },
        :body => { :string => "value" }
      })

      expect{Encoder.new.serialize_request(req)}.to raise_error(UnsupportedEncodingError, /Unable to serialize request with Content-Type .*\. Supported encodings are .*/)
    end

    it 'throws when headers undefined' do
      req = OpenStruct.new({
        :body => { :string => "value" }
      })

      expect{Encoder.new.serialize_request(req)}.to raise_error(UnsupportedEncodingError, 'HttpRequest did not have Content-Type header set')
    end
  end

  describe 'deserialize_response' do
    it 'throws when content-type not application/json' do
      body = '{"string":"value","number":1.23,"bool":true,"array":["one","two","three"],"nested":{"nested_string":"nested_value","nested_array":[1,2,3]}}'
      headers = {
        "content-type" => ["application/xml"]
      }

      expect{Encoder.new.deserialize_response(body, headers)}.to raise_error(UnsupportedEncodingError, /Unable to deserialize response with Content-Type .*\. Supported decodings are .*/)
    end

    it 'throws when headers undefined' do
      body = '{"string":"value","number":1.23,"bool":true,"array":["one","two","three"],"nested":{"nested_string":"nested_value","nested_array":[1,2,3]}}'

      expect{Encoder.new.deserialize_response(body, nil)}.to raise_error(UnsupportedEncodingError, 'HttpResponse did not have Content-Type header set')
    end

    it 'deserializes the response when content-type == application/json' do
      expected = {
        "string" => "value",
        "number" => 1.23,
        "bool" => true,
        "array" => ["one", "two", "three"],
        "nested" => {
          "nested_string" => "nested_value",
          "nested_array" => [1,2,3]
        }
      }

      headers = {"content-type" => ["application/json"]}
      body = '{"string":"value","number":1.23,"bool":true,"array":["one","two","three"],"nested":{"nested_string":"nested_value","nested_array":[1,2,3]}}'

      expect(Encoder.new.deserialize_response(body, headers)).to eq(expected)
    end

    it 'deserializes the response when content-type == text/*' do
      headers = {"content-type" => ["text/plain"]}
      body = 'some text'

      expect(Encoder.new.deserialize_response(body, headers)).to eq('some text')
    end
  end
end
