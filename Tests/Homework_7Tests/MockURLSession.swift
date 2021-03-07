//
//  MockURLSession.swift
//  
//
//  Created by Sasha on 05/03/2021.
//

import Foundation
@testable import Homework_7

class MockURLSession: URLSessionProxy {

    var nextDataTask = MockURLSessionDataTask()
    var nextData: Data?
    var nextError: Error?
    var nextStatusCode: Int = 200
    
    private (set) var lastURL: URL?
    
    func httpURLResponse(request: URLRequest) -> URLResponse {
        return HTTPURLResponse(url: request.url!, statusCode: nextStatusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProxy {
        lastURL = request.url
        
        completionHandler(nextData, httpURLResponse(request: request), nextError)
        return nextDataTask
    }

}

class MockURLSessionDataTask: URLSessionDataTaskProxy {
    private (set) var resumeWasCalled = false
    
    func resume() {
        resumeWasCalled = true
    }
}
