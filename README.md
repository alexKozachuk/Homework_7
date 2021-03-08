# Homework_7

This is a simple library for easy working with URLSession

To make a request you need to create instance of NetworkLibrary, and create dataTask from it. Using dataTask You can make simple request and get specific data (such as Decodable, String or JSON)

Example of simple request

```swift
let url = "https://mockurl"
let dataTask = networkLibrary.request(url: url)


dataTask.response { response in
    guard let data = try? response.result.get() else {
        // working with data
        return
    }
}
```

Example of post request

```swift
let url = "https://mockurl"
let param: [String: Any] = ["mockTypeString": "mockValue",
                            "mockTypeInt": 1,
                            "mockTypeBool": true]
let dataTask = networkLibrary.request(url: url, httpMethod: .post,
                                      parameters: param, parametersType: .httpBody)

session.nextData = expectedData

dataTask.response { response in
    switch response.result {
    case .success(let data):
        // working with data
    case .failure(let error):
        // working with error
    }
}
```

Example of decodable request

```swift

let url = "https://mockurl"
let dataTask = networkLibrary.request(url: url)

dataTask.responseDecodable(of: SomeDecodable.self) { response in
    switch response.result {
    case .success(let item):
        // working with item of SomeDecodable
    case .failure(let error):
        // working with error
    }
    exp.fulfill()
}

```

Example of validation request

```swift
let url = "https://mockurl"

networkLibrary.request(url: url)
              .validate(statusCode: 100..<200)
              .validate(contentType: "application/json; charset=utf-8")
              .response { response in
                switch response.result {
                case .success(let data):
                    // working with data
                case .failure(let error):
                    // working with error
                }
}

```
