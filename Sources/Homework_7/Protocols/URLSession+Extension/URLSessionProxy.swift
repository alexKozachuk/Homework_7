//
//  URLSessionProxy.swift
//  
//
//  Created by Sasha on 05/03/2021.
//

import Foundation

public protocol URLSessionProxy {
    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
    
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProxy
}

extension URLSession: URLSessionProxy {
    public func dataTask(with request: URLRequest,
                         completionHandler: @escaping URLSessionProxy.DataTaskResult) -> URLSessionDataTaskProxy {
        return dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
    }
}
