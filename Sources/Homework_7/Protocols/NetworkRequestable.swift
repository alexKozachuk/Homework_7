//
//  NetworkRequestable.swift
//  
//
//  Created by Sasha on 05/03/2021.
//

import Foundation

public protocol NetworkRequestable {
    var headers: [String:String] { get }
    func request(url: String,
                 httpMethod: HTTPMethod,
                 httpHeaders: [HTTPHeader],
                 parameters: Parameters?,
                 parametersType: ParametersType) -> ResurseCombined
}
