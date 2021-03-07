//
//  NetworkLibrary.swift
//
//
//  Created by Sasha on 04/03/2021.
//

import Foundation

public final class NetworkLibrary {
    
    private(set) public var headers: [String:String]
    private let session: URLSessionProxy
    
    public init(headers: [HTTPHeader] = [], session: URLSessionProxy = URLSession.shared) {
        self.headers = headers.getDict()
        self.session = session
    }
    
    public func request(url: String, httpMethod: HTTPMethod = .get,
                        httpHeaders: [HTTPHeader] = [], parameters: Parameters? = nil,
                        parametersType: ParametersType = .defaultParam) -> DataTask {
        
        var unionHeaders = self.headers
        
        httpHeaders.forEach {
            unionHeaders[$0.name] = $0.value
        }
        
        return DataTask(url: url, httpMethod: httpMethod,
                        parameters: parameters, httpHeaders: unionHeaders,
                        parametersType: parametersType, session: session)
    }
    
}
