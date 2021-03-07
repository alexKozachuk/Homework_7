import XCTest
@testable import Homework_7

final class NetworkRequestableTest: XCTestCase {
    
    var networkLibrary: NetworkLibrary!
    var session = MockURLSession()
    
    override func setUp() {
        super.setUp()
        networkLibrary = NetworkLibrary(session: session)
    }
    
    
    // MARK: - Setup Resurse Tests
    
    func testSetupResurse() {
        let url = "https://mockurl"
        let header = HTTPHeader(name: "MockNameHeader", value: "MockValueHeader")
        var param: [String: Any] = ["mockTypeString": "mockValue", "mockTypeInt": 1, "mockTypeBool": true]
        let dataTask = networkLibrary.request(url: url, httpMethod: .get, httpHeaders: [header], parameters: param)
        param = ["mockTypeString": "mockValue", "mockTypeBool": true, "mockTypeInt": 1]
        
        XCTAssertEqual(dataTask.httpHeaders, [header].getDict())
        XCTAssertEqual(dataTask.httpMethod, .get)
        if let parameters = dataTask.parameters {
            XCTAssert(parameters == param)
        } else {
            XCTFail("Failed to cast parameters")
        }
        XCTAssertEqual(dataTask.parametersType, .defaultParam)
        XCTAssertEqual(dataTask.url, url)
        
    }
    
    func testRewriteHeaders() {
        
        let url = "https://mockurl"
        let mainHeaders = [HTTPHeader(name: "some name", value: "some value 1"),
                           HTTPHeader(name: "another name", value: "some value 2")]
        
        let nt = NetworkLibrary(headers: mainHeaders, session: session)
        
        let header = HTTPHeader(name: "some name", value: "some value 3")
        var expextedHeaders = mainHeaders.getDict()
        expextedHeaders[header.name] = header.value
        
        let dataTask = nt.request(url: url, httpHeaders: [header])
        
        XCTAssertEqual(dataTask.httpHeaders, expextedHeaders)
        
    }
    
    // MARK: - Success Tests
    
    func testPostResponseSuccess() {
        let exp = expectation(description: "should response")
        
        let expectedData =
            """
            {
                "id": 1,
                "title": "someTitle"
            }
            """.data(using: .utf8)
        
        let url = "https://mockurl"
        let param: [String: Any] = ["mockTypeString": "mockValue", "mockTypeInt": 1, "mockTypeBool": true]
        let dataTask = networkLibrary.request(url: url, httpMethod: .post, parameters: param, parametersType: .httpBody)
        
        session.nextData = expectedData
        
        dataTask.response { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, expectedData)
            default:
                XCTFail("Should receive success")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5)
    }
    
    func testGetResponseSuccess() {
        let exp = expectation(description: "should response")
        let expectedData =
            """
            {
                "id": 1,
                "title": "someTitle"
            }
            """.data(using: .utf8)
            
        
        let url = "https://mockurl"
        let header = HTTPHeader(name: "MockNameHeader", value: "MockValueHeader")
        let param = ["mockType": "mockValue"]
        let dataTask = networkLibrary.request(url: url, httpMethod: .get, httpHeaders: [header], parameters: param)
        
        session.nextData = expectedData
        
        dataTask.response { result in
            guard let data = try? result.get() else {
                XCTFail("Should receive data")
                return
            }
            
            XCTAssertEqual(data, expectedData)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5)
    }
    
    // MARK: - Test Setup in DataTask
    
    func testGetResponseFailureBuildUrl() {
        let exp = expectation(description: "should response")
        let url = "break url"
        
        let dataTask = networkLibrary.request(url: url)
        
        dataTask.response { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .buildUrlError)
            default:
                XCTFail("Should receive error")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    func testPostResponseFailureSendBodyWithoutParam() {
        let exp = expectation(description: "should response")
        let url = "https://mockurl"
        
        let dataTask = networkLibrary.request(url: url, httpMethod: .post, parametersType: .httpBody)
        
        dataTask.response { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .sendBodyWithoutParam)
            default:
                XCTFail("Should receive error")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    // MARK: - Response Test
    
    func testGetFailureCallMethodError() {
        let exp = expectation(description: "should response")
        let url = "https://mockurl"
        let dataTask = networkLibrary.request(url: url)
        let expectedError = NetworkError.unexpectedError
        
        session.nextError = expectedError
        
        dataTask.response { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .callMethodError(expectedError))
            default:
                XCTFail("Should receive error")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    func testGetFailureResiveDataError() {
        let exp = expectation(description: "should response")
        let url = "https://mockurl"
        let dataTask = networkLibrary.request(url: url)
        
        session.nextData = nil
        
        dataTask.response { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .resiveDataError)
            default:
                XCTFail("Should receive error")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    func testGetFailurehttpRequestError() {
        let exp = expectation(description: "should response")
        let url = "https://mockurl"
        let dataTask = networkLibrary.request(url: url)
        let expectedData = "{}".data(using: .utf8)
        
        session.nextStatusCode = 400
        session.nextData = expectedData
        
        dataTask.validate().response { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .httpRequestError)
            default:
                XCTFail("Should receive error")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    // MARK: - Response Decodable Tests
    
    func testResponseDecodableSuccess() {
        let exp = expectation(description: "should response")
        let expectedMock = Mock(id: 1, title: "someTitle")
        
        guard let expectedData = try? JSONEncoder().encode(expectedMock) else {
            XCTFail("Should receive expectedData")
            return
        }
        
        let url = "https://mockurl"
        
        session.nextData = expectedData
        
        let dataTask = networkLibrary.request(url: url)
        
        dataTask.responseDecodable(of: Mock.self) { result in
            switch result {
            case .success(let mock):
                XCTAssertEqual(mock, expectedMock)
            default:
                XCTFail("Should receive success")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5)
    }
    
    func testResponseDecodableError() {
        let exp = expectation(description: "should response")
        let url = "https://mockurl"
        
        let dataTask = networkLibrary.request(url: url)
        session.nextData = nil
        
        dataTask.responseDecodable(of: Mock.self) { result in
            switch result {
            case .success(_):
                XCTFail("Should receive failure")
            default:
                break
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    func testResponseJSONDecodableError() {
        let exp = expectation(description: "should response")
        let expectedBreakString =
            """
            {
                "id": 1,
                "title": "someTitle"
            
            """
        
        let url = "https://mockurl"
        let dataTask = networkLibrary.request(url: url)
        
        guard let expectedBreakData = expectedBreakString.data(using: .utf8) else {
            XCTFail("Should receive expectedData")
            return
        }
        
        session.nextData = expectedBreakData
        
        dataTask.responseDecodable(of: Mock.self) { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .jsonDecodeError)
            default:
                XCTFail("Should receive failure")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    // MARK: Response String Tests
    
    func testResponseStringSuccess() {
        let exp = expectation(description: "should response")
        let expectedString =
            """
            {
                "id": 1,
                "title": "someTitle"
            }
            """
        let expectedData = expectedString.data(using: .utf8)
        
        let url = "https://mockurl"
        
        session.nextData = expectedData
        
        let dataTask = networkLibrary.request(url: url)
        
        dataTask.responseString { result in
            switch result {
            case .success(let string):
                XCTAssertEqual(string, expectedString)
            default:
                XCTFail("Should receive success")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    func testResponseStringError() {
        let exp = expectation(description: "should response")
        let url = "https://mockurl"
        
        let dataTask = networkLibrary.request(url: url)
        session.nextData = nil
        
        dataTask.responseString { result in
            switch result {
            case .success(_):
                XCTFail("Should receive failure")
            default:
                break
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    // MARK: Response JSON Tests
    
    func testResponseJSONSuccess() {
        let exp = expectation(description: "should response")
        let expectedString =
            """
            {
                "id": 1,
                "title": "someTitle"
            }
            """
        guard let expectedData = expectedString.data(using: .utf8) else {
            XCTFail("Should receive expectedData")
            return
        }
        
        guard let expectedJSON = try? JSONSerialization.jsonObject(with: expectedData, options: []) else {
            XCTFail("Should receive expectedJSON")
            return
        }
        
        
        let url = "https://mockurl"
        
        session.nextData = expectedData
        
        let dataTask = networkLibrary.request(url: url)
        
        dataTask.responseJSON { result in
            switch result {
            case .success(let json):
                XCTAssertEqual("\(json)", "\(expectedJSON)")
            default:
                XCTFail("Should receive success")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    func testResponseJSONError() {
        let exp = expectation(description: "should response")
        let url = "https://mockurl"
        
        let dataTask = networkLibrary.request(url: url)
        session.nextData = nil
        
        dataTask.responseJSON { result in
            switch result {
            case .success(_):
                XCTFail("Should receive failure")
            default:
                break
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    func testResponseJSONDecodeError() {
        let exp = expectation(description: "should response")
        let expectedBreakString =
            """
            {
                "id": 1,
                "title": "someTitle"
            
            """
        
        let url = "https://mockurl"
        let dataTask = networkLibrary.request(url: url)
        
        guard let expectedBreakData = expectedBreakString.data(using: .utf8) else {
            XCTFail("Should receive expectedData")
            return
        }
        
        session.nextData = expectedBreakData
        
        dataTask.responseJSON { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .jsonDecodeError)
            default:
                XCTFail("Should receive failure")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    // MARK: Validate Tests
    
    func testResponseValidateStatusCode() {
        let exp = expectation(description: "should response")
        let url = "https://mockurl"
        let expextedStatusCode = 1..<100
        
        session.nextStatusCode = 101
        
        let dataTask = networkLibrary.request(url: url).validate(statusCode: expextedStatusCode)
        
        dataTask.response { result in
            
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .httpRequestError)
            default:
                XCTFail("Should receive failure")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
        
    func testResponseValidateContentType() {
        let url = "https://mockurl"
        let expextedContentType = "mock content type"
        
        let dataTask = networkLibrary.request(url: url).validate(contentType: expextedContentType)
        
        XCTAssertEqual(dataTask.httpHeaders["Content-type"], expextedContentType)
    }

    static var allTests = [
        ("testSetupResurse", testSetupResurse),
        ("testRewriteHeaders", testRewriteHeaders),
        ("testPostResponseSuccess", testPostResponseSuccess),
        ("testGetResponseSuccess", testGetResponseSuccess),
        ("testGetResponseFailureBuildUrl", testGetResponseFailureBuildUrl),
        ("testPostResponseFailureSendBodyWithoutParam", testPostResponseFailureSendBodyWithoutParam),
        ("testGetFailureCallMethodError", testGetFailureCallMethodError),
        ("testGetFailureResiveDataError", testGetFailureResiveDataError),
        ("testGetFailurehttpRequestError", testGetFailurehttpRequestError),
        ("testResponseDecodableSuccess", testResponseDecodableSuccess),
        ("testResponseDecodableError", testResponseDecodableError),
        ("testResponseJSONDecodableError", testResponseJSONDecodableError),
        ("testResponseStringSuccess", testResponseStringSuccess),
        ("testResponseStringError", testResponseStringError),
        ("testResponseJSONSuccess", testResponseJSONSuccess),
        ("testResponseJSONError", testResponseJSONError),
        ("testResponseJSONDecodeError", testResponseJSONDecodeError),
        ("testResponseValidateStatusCode", testResponseValidateStatusCode),
        ("testResponseValidateContentType", testResponseValidateContentType)
    ]
}

