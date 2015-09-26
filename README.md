# NaiveHTTP

Work-in-progress at a focused `NSURLSession` wrapper.

## Usage

This is a framework, so you can either build it as such or include it as a submodule/subproject and link it to your binary in Build Phases.

```swift
let sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
let naive = NaiveHTTP(configuration: sessionConfig)

let query = ["key1":"value1", "key2":"value2"]
let customHeaders = ["X-Some-Header" : "Feh"]

naive.GET(
    "http://example.org/thing", 
    params: query,
    headers: customHeaders) { (data, response, error) -> Void in
        XCTAssertEqual(400, error?.code)
        self.networkExpectation!.fulfill()
    }
```

Convenience functions, like `jsonGET` let you work with "pure JSON" endpoints.

## Protocols

This project is taking on some shape with respect to use of Protocols, which has been helping with testing against fake network responses.

## Tests

The main suite runs against <http://httpbin.org> but is configurable to run against your own local instance of it. Check the `NAIVEHTTP_EXTERNAL_TEST_SERVER` and set it to the appropriate value.

If you want to run your own local `httpbin` you can use Python and PIP:

```sh
pip install httpbin
python -m httpbin.core
```

You can read more info about running a local `httpbin` at <https://github.com/Runscope/httpbin>


