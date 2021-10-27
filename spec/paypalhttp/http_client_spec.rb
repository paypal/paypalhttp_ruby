require 'net/http'
require 'ostruct'

describe HttpClient do

  before do
    WebMock.disable!
    @environment = Environment.new('https://ip.jsontest.com')
  end

  it "uses injectors to modify request" do
    WebMock.enable!

    http_client = HttpClient.new(@environment)

    http_client.add_injector do |request|
      request.headers["Some-Key"] = "Some Value"
    end

    req = OpenStruct.new({:verb => "GET", :path => "/"})

    stub_request(:any, @environment.base_url)

    http_client.execute(req)

    assert_requested :get, "#{@environment.base_url}/", {
      :headers => {'Some-Key' => 'Some Value'},
      :times => 1
    }
  end

  it "uses method injector to modify request" do
    WebMock.enable!

    http_client = HttpClient.new(@environment)

    def _inj(req)
      req.headers["Some-Key"] = "Some Value"
    end

    http_client.add_injector(&method(:_inj))

    req = OpenStruct.new({:verb => "GET", :path => "/"})

    stub_request(:any, @environment.base_url)

    http_client.execute(req)

    assert_requested :get, "#{@environment.base_url}/", {
      :headers => {'Some-Key' => 'Some Value'},
      :times => 1
    }
  end

  it "sets User-Agent header in request if not set" do
    WebMock.enable!

    http_client = HttpClient.new(@environment)
    req = OpenStruct.new({:verb => "GET", :path => "/"})

    stub_request(:any, @environment.base_url)

    http_client.execute(req)

    assert_requested :get, "#{@environment.base_url}/", {
      :headers => {"User-Agent" => "PayPalHttp-Ruby HTTP/1.1"},
      :times => 1
    }
  end

  it "does not overwrite User-Agent header if set" do
    WebMock.enable!

    http_client = HttpClient.new(@environment)

    req = OpenStruct.new({:verb => "GET", :path => "/", :headers => {"User-Agent" => "Not Ruby Http/1.1"}})

    stub_request(:any, @environment.base_url)

    http_client.execute(req)

    assert_requested :get, "#{@environment.base_url}/", {
      :headers => {"User-Agent" => "Not Ruby Http/1.1"},
      :times => 1
    }
  end

  it "does not modify the original request" do
    WebMock.enable!

    http_client = HttpClient.new(@environment)

    req = OpenStruct.new({:verb => "GET", :path => "/"})

    stub_request(:any, @environment.base_url)

    http_client.execute(req)

    expect(req.headers).to be_nil
  end

  it "uses body in request" do
    WebMock.enable!

    stub_request(:delete, @environment.base_url + "/path")

    req = OpenStruct.new({
      :verb => "DELETE",
      :path => "/path",
      :headers => {
        "Content-Type" => "text/plain"
      }
    })

    req.body = "I want to delete the thing"

    http_client = HttpClient.new(@environment)

    resp = http_client.execute(req)
    expect(resp.status_code).to eq(200)

    assert_requested(:delete, @environment.base_url + "/path") { |requested| requested.body == "I want to delete the thing" }
  end

  it "parses 200 level response" do
    WebMock.enable!

    return_data = JSON.generate({
      :some_key => "value"
    })

    stub_request(:any, @environment.base_url).
      to_return(body: return_data, status: 204,
                headers: {
        'Some-Weird-Header' => 'Some weird value',
        'Content-Type' => 'application/json'
    })

    http_client = HttpClient.new(@environment)
    req = OpenStruct.new({:verb => "GET", :path => "/"})

    resp = http_client.execute(req)

    expect(resp.status_code).to eq(204)
    expect(resp.result.some_key).to eq('value')
    expect(resp.headers["Some-Weird-Header".downcase]).to eq(["Some weird value"])
  end

  it "throws for non-200 level response" do
    WebMock.enable!

    return_data = {
      :error => "error message",
      :another_key => 1013
    }

    json = JSON.generate(return_data)

    stub_request(:any, @environment.base_url).
      to_return(body: json, status: 400,
                headers: {
        'Some-Weird-Header' => 'Some weird value',
        'Content-Type' => 'application/json'
      })

    http_client = HttpClient.new(@environment)
    req = OpenStruct.new({:verb => "GET", :path => URI(@environment.base_url)})

    begin
      resp = http_client.execute(req)
      fail
    rescue => e
      resp = e
      expect(resp.status_code).to eq(400)
      expect(resp.result.error).to eq('error message')
      expect(resp.result.another_key).to eq(1013)
      expect(resp.headers["Some-Weird-Header".downcase]).to eq(["Some weird value"])
    end
  end

  it "makes request when only a path is specified" do
    WebMock.enable!

    stub_request(:any, @environment.base_url + "/v1/api")
      .to_return(status: 200)

    http_client = HttpClient.new(@environment)
    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)
    expect(resp.status_code).to eq(200)
  end

  it 'uses encoder to serialize requests by default' do
    WebMock.enable!

    return_data = {
      :key => "value"
    }

    http_client = HttpClient.new(@environment)
    stub_request(:get, @environment.base_url + "/v1/api")
      .to_return(body: JSON.generate(return_data), status: 200, headers: {"Content-Type" => "application/json"})

    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})
    resp = http_client.execute(req)

    expect(resp.status_code).to eq(200)
    expect(resp.result.key).to eq('value')
  end

  it 'handles json array result' do
    WebMock.enable!

    return_data = ["one", "two"]

    http_client = HttpClient.new(@environment)

    stub_request(:get, @environment.base_url + "/v1/api")
      .to_return(body: JSON.generate(return_data), status: 200, headers: {"Content-Type" => "application/json"})

    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)

    expect(resp.result).to eq(return_data)
  end

  it 'handles json array result: case insensitive' do
    WebMock.enable!

    return_data = ["one", "two"]

    http_client = HttpClient.new(@environment)

    stub_request(:get, @environment.base_url + "/v1/api")
      .to_return(body: JSON.generate(return_data), status: 200, headers: {"Content-Type" => "application/JSON"})

    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)

    expect(resp.result).to eq(return_data)
  end

  it 'handles plain text result' do
    WebMock.enable!

    return_data = "value"

    http_client = HttpClient.new(@environment)

    stub_request(:get, @environment.base_url + "/v1/api")
      .to_return(body: return_data, status: 200, headers: {"Content-Type" => "text/plain; charset=utf8"})

    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)

    expect(resp.result).to eq(return_data)
  end

  it 'handles plain text result: case insensitive' do
    WebMock.enable!

    return_data = "value"

    http_client = HttpClient.new(@environment)

    stub_request(:get, @environment.base_url + "/v1/api")
      .to_return(body: return_data, status: 200, headers: {"Content-Type" => "TEXT/plain; charset=utf8"})

    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)

    expect(resp.result).to eq(return_data)
  end

  it 'deserializes nested response object into nested openstruct response' do
    WebMock.enable!

    return_data = {
      :key => 'value',
      :nested_key => {
        :string => 'stringvalue',
        :some_hash => {
          :some_int => 1
        },
        :some_array => [[{
          :array_key => 'array-value'
        }]]
      }
    }

    http_client = HttpClient.new(@environment)

    stub_request(:get, @environment.base_url + "/v1/api")
      .to_return(body: JSON.generate(return_data), status: 200, headers: {"Content-Type" => "application/json"})

    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)

    expect(resp.result.key).to eq('value')
    expect(resp.result.nested_key.string).to eq('stringvalue')
    expect(resp.result.nested_key.some_hash.some_int).to eq(1)
    expect(resp.result.nested_key.some_array[0][0].array_key).to eq('array-value')
  end

	it "does not error if no file or body present on a request class" do
		class Request

			attr_accessor :path, :body, :headers, :verb, :file

			def initialize()
				@headers = {}
				@verb = "POST"
				@path = "/v1/api"
			end
		end

		WebMock.enable!

		stub_request(:any, @environment.base_url + "/v1/api")
    http_client = HttpClient.new(@environment)

		begin
			http_client.execute(Request.new)
		rescue Exception => e
			fail e.message
		end
  end

  it 'handles frozen header fields' do
    WebMock.enable!

    return_data = ["one", "two"]

    http_client = HttpClient.new(@environment)

    stub_request(:get, @environment.base_url + "/v1/api")
      .to_return(body: JSON.generate(return_data), status: 200, headers: {"Content-Type".freeze => "application/JSON".freeze})

    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)

    expect(resp.result).to eq(return_data)
  end
end

