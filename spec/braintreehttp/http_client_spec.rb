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

    class CustomInjector < Injector
      def inject(request)
        request.headers["Some-Key"] = "Some Value"
      end
    end

    http_client.add_injector(CustomInjector.new)
    req = OpenStruct.new({:verb => "GET", :path => "/"})

    stub_request(:any, @environment.base_url)

    http_client.execute(req)

    expect(req.headers["Some-Key"]).to eq("Some Value")
  end

  it "sets User-Agent header in request if not set" do
    WebMock.enable!

    http_client = HttpClient.new(@environment)
    req = OpenStruct.new({:verb => "GET", :path => "/"})

    stub_request(:any, @environment.base_url)

    http_client.execute(req)

    expect(req.headers["User-Agent"]).to eq("BraintreeHttp-Ruby HTTP/1.1")
  end

  it "does not overwrite User-Agent header if set" do
    WebMock.enable!

    http_client = HttpClient.new(@environment)

    req = OpenStruct.new({:verb => "GET", :path => "/", :headers => {"User-Agent" => "Not Ruby Http/1.1"}})

    stub_request(:any, @environment.base_url)

    http_client.execute(req)

    expect(req.headers["User-Agent"]).to eq("Not Ruby Http/1.1")
  end

  it "uses body in request" do
    WebMock.enable!

    stub_request(:delete, @environment.base_url + "/path")

    req = OpenStruct.new({:verb => "DELETE", :path => "/path"})

    req.body = "I want to delete the thing"

    http_client = HttpClient.new(@environment)

    resp = http_client.execute(req)
    expect(resp.status_code).to eq("200")

    assert_requested(:delete, @environment.base_url + "/path") { |requested| requested.body == "I want to delete the thing" }
  end

  it "parses 200 level response" do
    WebMock.enable!

    return_data = "some data from the server"

    stub_request(:any, @environment.base_url).
      to_return(body: return_data, status: 204,
                headers: { 'Some-Weird-Header' => "Some weird value" })

    http_client = HttpClient.new(@environment)
    req = OpenStruct.new({:verb => "GET", :path => "/"})

    resp = http_client.execute(req)

    expect(resp.status_code).to eq("204")
    expect(resp.result).to eq(return_data)
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
                headers: { 'Some-Weird-Header' => "Some weird value" })

    http_client = HttpClient.new(@environment)
    req = OpenStruct.new({:verb => "GET", :path => URI(@environment.base_url)})

    begin
      resp = http_client.execute(req)
      fail
    rescue => e
      resp = e
      expect(resp.status_code).to eq("400")
      expect(resp.result).to eq(json)
      expect(resp.headers["Some-Weird-Header".downcase]).to eq(["Some weird value"])
    end
  end

  it "makes request when only a path is specified" do
    WebMock.enable!

    return_data = "some data"

    stub_request(:any, @environment.base_url + "/v1/api")
      .to_return(body: return_data, status: 200)

    http_client = HttpClient.new(@environment)
    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)
    expect(resp.status_code).to eq("200")
    expect(resp.result).to eq(return_data)
  end

  it "allows subclasses to modify response body" do
    WebMock.enable!

    return_data = {
      :key => "value"
    }

    class JSONHttpClient < HttpClient
      def deserializeResponse(body, headers)
        if headers["content-type"].include? "application/json"
          return OpenStruct.new(JSON.parse(body))
        end

        body
      end
    end

    http_client = JSONHttpClient.new(@environment)

    stub_request(:get, @environment.base_url + "/v1/api")
      .to_return(body: JSON.generate(return_data), status: 200, headers: {"Content-Type" => "application/json"})

    req = OpenStruct.new({:verb => "GET", :path => "/v1/api"})

    resp = http_client.execute(req)

    expect(resp.status_code).to eq("200")
    expect(resp.result.key).to eq("value")
  end

  it "encodes multipart/form-data when a file is present without body" do
    WebMock.enable!

    stub_request(:any, @environment.base_url + "/v1/api")

    http_client = HttpClient.new(@environment)
    file = File.new("README.md", "r")
    req = OpenStruct.new({:verb => "POST", :path => "/v1/api", :file => file})

    resp = http_client.execute(req)

    assert_requested(:post, @environment.base_url + "/v1/api") { |requested|
      requested.body.include? "Content-Disposition: form-data; name=\"file\"; filename=\"README.md\""
    }
  end

  it "encodes multipart/form-data when a file is present with body" do
    WebMock.enable!

    stub_request(:any, @environment.base_url + "/v1/api")

    http_client = HttpClient.new(@environment)
    file = File.new("README.md", "r")

    req = OpenStruct.new({:verb => "POST", :path => "/v1/api", :file => file})
    req.body = {
      :key => "value",
      :another_key => 1013
    }

    resp = http_client.execute(req)

    assert_requested(:post, @environment.base_url + "/v1/api") { |requested|
      requested.body.include? "Content-Disposition: form-data; name=\"file\"; filename=\"README.md\""
      requested.body.include? "Content-Disposition: form-data; name=\"key\""
      requested.body.include? "value"
      requested.body.include? "Content-Disposition: form-data; name=\"another_key\""
      requested.body.include? "1013"
    }
  end

	it "does not error if no file or body present on a request class" do
		class Request

			attr_accessor :path, :body, :headers, :verb, :file

			def initialize()
				@headers = {}
				@verb = "POST"
				@path = "/v1/api"
			end

			def requestBody(body)
				@body = body
			end

			def setFile(file)
				@file = file
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

end

