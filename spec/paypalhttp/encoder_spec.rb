require 'ostruct'
require 'json'
require 'stringio'
require 'zlib'

describe Encoder do

  describe 'serialize_request' do
    it 'serializes the request when content-type == application/json' do
      req = OpenStruct.new({
        :headers  => {
          "content-type" => "application/json; charset=utf8"
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
          "content-type" => "text/plain; charset=utf8"
        },
        :body => "some text"
      })

      expect(Encoder.new.serialize_request(req)).to eq("some text")
    end

    it 'serializes the request when content-type == multipart/form-data' do
      file = File.new("README.md", "r")
      req = OpenStruct.new({
        :verb => "POST",
        :path => "/v1/api",
        :headers => {
          "content-type" => "multipart/form-data; charset=utf8"
        },
        :body => {
          :key => "value",
          :another_key => 1013,
          :readme => file
        }
      })

      serialized = Encoder.new.serialize_request(req)

      expect(req.headers['content-type']).to include('multipart/form-data; charset=utf8; boundary=')

      expect(serialized).to include("Content-Disposition: form-data; name=\"readme\"; filename=\"README.md\"")
      expect(serialized).to include("Content-Disposition: form-data; name=\"key\"")
      expect(serialized).to include("value")
      expect(serialized).to include("Content-Disposition: form-data; name=\"another_key\"")
      expect(serialized).to include("1013")
    end

    it 'serializes the request when Json is provided inside multipart/form-data' do
      file = File.new("README.md", "r")
      req = OpenStruct.new({
        :verb => "POST",
        :path => "/v1/api",
        :headers => {
          "content-type" => "multipart/form-data; charset=utf8"
        },
        :body => {
          :readme => file,
          :input=> FormPart.new({:key => 'val'}, {'content-type': 'application/json'}),
        }
      })

      serialized = Encoder.new.serialize_request(req)

      expect(req.headers['content-type']).to include('multipart/form-data; charset=utf8; boundary=')

      expect(serialized).to include("Content-Disposition: form-data; name=\"readme\"; filename=\"README.md\"")
      expect(serialized).to include("Content-Type: application/octet-stream")
      expect(serialized).to include("Content-Disposition: form-data; name=\"input\"; filename=\"input.json\"")
      expect(serialized).to include("Content-Type: application/json")
      expect(serialized).to include("{\"key\":\"val\"}")
      expect(serialized).to match(/.*Content-Disposition: form-data; name=\"input\"; filename=\"input.json\".*Content-Disposition: form-data; name=\"readme\"; filename=\"README.md\".*/m)
    end

    it 'serializes the request when content-type == application/x-www-form-urlencoded' do
      req = OpenStruct.new({
        :verb => "POST",
        :path => "/v1/api",
        :headers => {
          "content-type" => "application/x-www-form-urlencoded; charset=utf8"
        },
        :body => {
          :key => "value with a space",
          :another_key => 1013,
        }
      })
      serialized = Encoder.new.serialize_request(req)

      expect(serialized).to eq("key=value%20with%20a%20space&another_key=1013")
    end

    it 'throws when content-type is unsupported' do
      req = OpenStruct.new({
        :headers  => {
          "content-type" => "fake/content-type"
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

    it 'throws when conent-type undefined' do
      req = OpenStruct.new({
        :headers => {},
        :body  => { :key => "value" }
      })


      expect{Encoder.new.serialize_request(req)}.to raise_error(UnsupportedEncodingError, 'HttpRequest did not have Content-Type header set')
    end

    it 'encodes data as gzip when content-encoding == gzip' do
      req = OpenStruct.new({
        :path => '/143j2bz1',
        :verb => "POST",
        :headers => {
          'content-type' => 'application/json',
          'content-encoding' => 'gzip'
        },
        :body => {
          :one => "two"
        }
      })

      encoder = Encoder.new

      out = StringIO.new('w')
      writer = Zlib::GzipWriter.new(out)
      writer.write JSON.generate(req.body)
      writer.close

      expected_body = out.string

      expect(encoder.serialize_request(req)).to eq(expected_body)
    end
  end

  describe 'deserialize_response' do
    it 'throws when content-type unsupported' do
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

    it 'throws when content-type undefined' do
      body = '{"string":"value","number":1.23,"bool":true,"array":["one","two","three"],"nested":{"nested_string":"nested_value","nested_array":[1,2,3]}}'

      expect{Encoder.new.deserialize_response(body, {})}.to raise_error(UnsupportedEncodingError, 'HttpResponse did not have Content-Type header set')
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

      headers = {"content-type" => ["application/json; charset=utf8"]}
      body = '{"string":"value","number":1.23,"bool":true,"array":["one","two","three"],"nested":{"nested_string":"nested_value","nested_array":[1,2,3]}}'

      deserialized = Encoder.new.deserialize_response(body, headers)

      expect(deserialized).to eq(expected)
    end

    it 'deserializes the response when content-type == application/json: case insensitive' do
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

      headers = {"content-type" => ["application/JSON; charset=utf8"]}
      body = '{"string":"value","number":1.23,"bool":true,"array":["one","two","three"],"nested":{"nested_string":"nested_value","nested_array":[1,2,3]}}'

      deserialized = Encoder.new.deserialize_response(body, headers)

      expect(deserialized).to eq(expected)
    end

    it 'handles frozen header fields' do
      headers = {"content-type".freeze => ["application/JSON; charset=utf8".freeze]}

      deserialized = Encoder.new.deserialize_response('{}', headers)

      expect(deserialized).to eq({})
    end

    it 'deserializes the response when content-type == text/*' do
      headers = {"content-type" => ["text/plain; charset=utf8"]}
      body = 'some text'

      expect(Encoder.new.deserialize_response(body, headers)).to eq('some text')
    end

    it 'deserializes the response when content-type == text/*: case insensitive' do
      headers = {"content-type" => ["TEXT/plain; charset=utf8"]}
      body = 'some text'

      expect(Encoder.new.deserialize_response(body, headers)).to eq('some text')
    end

    it 'throws when attempting to deserialize multipart/*' do
      headers = {"content-type" => ["multipart/form-data"]}
      body = 'some multipart encoded data here'

      expect{Encoder.new.deserialize_response(body, headers)}.to raise_error(UnsupportedEncodingError, 'Multipart does not support deserialization')
    end

    it 'throws when attempting to deserialize application/x-www-form-urlencoded' do
      headers = {"content-type" => ["application/x-www-form-urlencoded"]}
      body = 'some multipart encoded data here'

      expect{Encoder.new.deserialize_response(body, headers)}.to raise_error(UnsupportedEncodingError, 'FormEncoded does not support deserialization')
    end

    it 'decodes data from gzip when content-encoding == gzip' do
      headers = {
        'content-type' => 'application/json',
        'content-encoding' => 'gzip'
      }
      body = JSON.generate({
        :one => 'two'
      })

      out = StringIO.new('w')
      encoder = Zlib::GzipWriter.new(out)
      encoder.write(body)
      encoder.close
      encoded_body = out.string

      expect(Encoder.new.deserialize_response(encoded_body, headers)).to eq({'one' => 'two'})
    end
  end
end
