require 'net/http'

describe DefaultHttpClient do

  before do
    WebMock.disable!
    @environment = Environment.new('https://ip.jsontest.com')
  end

  it "uses injectors to modify request" do
    http_client = DefaultHttpClient.new(@environment)

    class CustomInjector < Injector
      def inject(request)
        request["Some-Key"] = "Some Value"
      end
    end

    http_client.add_injector(CustomInjector.new)
    req = Net::HTTP::Get.new(URI(@environment.base_url))

    begin
      http_client.execute(req)
    rescue
    end

    expect(req["Some-Key"]).to eq("Some Value")
  end

  it "sets User-Agent header in request if not set" do
    http_client = DefaultHttpClient.new(@environment)
    req = Net::HTTP::Get.new(URI(@environment.base_url))

    begin
      http_client.execute(req)
    rescue
    end

    expect(req["User-Agent"]).not_to be_empty
  end

  it "does not overwrite User-Agent header if set" do
    http_client = DefaultHttpClient.new(@environment)
    req = Net::HTTP::Get.new(URI(@environment.base_url))
    req["User-Agent"] = "Not Ruby Http/1.1"

    begin
      http_client.execute(req)
    rescue
    end

    expect(req["User-Agent"]).to eq("Not Ruby Http/1.1")
  end

  it "uses parameters in request" do
    WebMock.enable!

    expected_body = {
      :foo  => "bar",
      :something_else => {
        :another_key  => "some other thing",
      },
    }

    stub_request(:delete, @environment.base_url + "/path")
      .with(body: JSON.generate(expected_body))

    req = Net::HTTP::Delete.new("/path")
    req.body = JSON.generate(expected_body)

    http_client = DefaultHttpClient.new(@environment)

    begin
      resp = http_client.execute(req)
      expect(resp.status_code).to eq("200")
    rescue => e
      expect(e).to be_nil
    end
  end

  it "parses 200 level response" do
    WebMock.enable!

    return_data = {
      :key => "value",
      :another_key => 3
    }

    json = JSON.generate(return_data)

    stub_request(:any, @environment.base_url).
      to_return(body: json, status: 204,
                headers: { 'Some-Weird-Header' => "Some weird value" })

      http_client = DefaultHttpClient.new(@environment)
      req = Net::HTTP::Get.new(URI(@environment.base_url))

      resp = http_client.execute(req)

      json_result = JSON.parse(resp.result)
      expect(resp.status_code).to eq("204")
      expect(resp.result).to eq(json)
      expect(resp.headers["Some-Weird-Header".downcase]).to eq(["Some weird value"])
  end

  it "makes request when only a path is specified" do
    WebMock.enable!

    return_data = {
      :error => "error message",
      :another_key => 1013
    }

    json = JSON.generate(return_data)

    stub_request(:any, @environment.base_url + "/v1/api").
      to_return(body: json, status: 400,
                headers: { 'Some-Weird-Header' => "Some weird value" })

      http_client = DefaultHttpClient.new(@environment)
      req = Net::HTTP::Get.new("/v1/api")

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

      http_client = DefaultHttpClient.new(@environment)
      req = Net::HTTP::Get.new(URI(@environment.base_url))

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
end

