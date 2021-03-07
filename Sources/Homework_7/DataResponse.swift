//
//  File.swift
//  
//
//  Created by Sasha on 07/03/2021.
//

import Foundation

public struct DataResponse<T> {
    
    public let result: Result<T, NetworkError>
    public let request: URLRequest?
    public let response: HTTPURLResponse?
    
    public init(result: Result<T, NetworkError>, request: URLRequest? = nil, response: HTTPURLResponse? = nil) {
        self.result = result
        self.request = request
        self.response = response
    }
}
