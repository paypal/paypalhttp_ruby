require 'net/http'

describe DefaultHttpClient do

  before do
    WebMock.disable!
  end

  it "uses injectors to modify request" do
    http_client = DefaultHttpClient.new

    class CustomInjector < Injector
      def inject(request)
        request["Some-Key"] = "Some Value"
      end
    end

    http_client.add_injector(CustomInjector.new)
    req = Net::HTTP::Get.new(URI('http://ip.jsontest.com/'))

    begin
      http_client.execute(req)
    rescue
    end

    expect(req["Some-Key"]).to eq("Some Value")
  end

  it "sets User-Agent header in request if not set" do
    http_client = DefaultHttpClient.new
    req = Net::HTTP::Get.new(URI('http://ip.jsontest.com/'))

    begin
      http_client.execute(req)
    rescue
    end

    expect(req["User-Agent"]).not_to be_empty
  end

  it "does not overwrite User-Agent header if set" do
    http_client = DefaultHttpClient.new
    req = Net::HTTP::Get.new(URI('http://ip.jsontest.com/'))
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

    stub_request(:delete, "http://some-fake-host")
      .with(body: JSON.generate(expected_body))

    req = Net::HTTP::Delete.new(URI("http://some-fake-host"))
    req.body = JSON.generate(expected_body)

    http_client = DefaultHttpClient.new

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

    stub_request(:any, "www.example.com").
      to_return(body: json, status: 204,
                headers: { 'Some-Weird-Header' => "Some weird value" })

      http_client = DefaultHttpClient.new
      req = Net::HTTP::Get.new(URI('http://www.example.com'))

      resp = http_client.execute(req)

      expect(resp.status_code).to eq("204")
      expect(resp.result.key).to eq("value")
      expect(resp.result.another_key).to eq(3)
      expect(resp.headers["Some-Weird-Header".downcase]).to eq(["Some weird value"])
  end

  it "throws for non-200 level response" do
    WebMock.enable!

    return_data = {
      :error => "error message",
      :another_key => 1013
    }

    json = JSON.generate(return_data)

    stub_request(:any, "www.example.com").
      to_return(body: json, status: 400,
                headers: { 'Some-Weird-Header' => "Some weird value" })

      http_client = DefaultHttpClient.new
      req = Net::HTTP::Get.new(URI('http://www.example.com'))

      begin
        resp = http_client.execute(req)
        fail
      rescue => e
        resp = e
        expect(resp.status_code).to eq("400")
        expect(resp.result.error).to eq("error message")
        expect(resp.result.another_key).to eq(1013)
        expect(resp.headers["Some-Weird-Header".downcase]).to eq(["Some weird value"])
      end
  end
end

