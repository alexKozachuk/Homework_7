//
//  File.swift
//  
//
//  Created by Sasha on 07/03/2021.
//

import Foundation

public protocol URLSessionDataTaskProxy {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProxy {}
