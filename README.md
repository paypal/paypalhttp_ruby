## Braintree HttpClient

BraintreeHttp is a generic HTTP Client.

In it's simplest form, an [`HttpClient`](./lib/braintreehttp/http_client.rb) exposes an `#execute` method which takes an HTTP request, executes it against the domain described in an `Environment`, and returns an HTTP response.

### Environment

An [`Environment`](./lib/braintreehttp/environment.rb) describes a domain that hosts a REST API, against which an `HttpClient` will make requests. `Environment` is a simple class that contains one property, `base_url`.

```ruby
env = Environment.new('https://example.com')
```

### Requests

HTTP requests contain all the information needed to make an HTTP request against the REST API. Specifically, one request describes a path, a verb, any path/query/form parameters, headers, attached files for upload, and body data. In Ruby, an HTTP request is simply an OpenStruct literal with `path`, `verb`, and optionally, `request_body`, and `headers` populated.

### Responses

HTTP responses contain information returned by a server in response to a request as described above. They are simple objects which contain a `status_code`, `headers`, and a `result`, which reprepsents any data returned by the server.

```ruby
req = OpenStruct.new({
  :path => 'path/to/resource',
  :verb => 'GET',
  :headers => {
    'X-Custom-Header' => 'custom_value'
  }
})

resp = client.execute(req)
status_code = resp.status_code;
headers = resp.headers;
response_data = resp.result;
```

### Injectors

Injectors are blocks that can be used for executing arbitrary pre-flight logic, such as modifying a request or logging data. Injectors are attached to an `HttpClient` using the `#add_injector` method. They must take one argument (a request).

The `HttpClient` executes its injectors in a first-in, first-out order, before each request.

```ruby
let client = new HttpClient(env);
client.add_injector do |request|
  puts req
end

client.add_injector do |request|
  req.headers['Request-Id'] = 'abcd'
end

...
```

### Error Handling

`HttpClient#execute` may throw an `IOError` if something went wrong during the course of execution. If the server returned a non-200 response, this execption will be an instance of [`HttpError`](./lib/braintreehttp/errors.rb) that will contain a status code and headers you can use for debugging.

```ruby
begin
  resp = http_client.execute(req)
rescue => e
  if e.is_a? HttpError
    # Inspect this exception for details
    status_code = e.status_code;
  end
end
```

### Serializer
(De)Serialization of request and response data is done by instances of [`Encoder`](./lib/braintreehttp/encoder.rb). BraintreeHttp currently supports `json` encoding out of the box.

## License
BraintreeHttp-Ruby is open source and available under the MIT license. See the [LICENSE](./LICENSE) file for more information.

## Contributing
Pull requests and issues are welcome. Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for more details.
