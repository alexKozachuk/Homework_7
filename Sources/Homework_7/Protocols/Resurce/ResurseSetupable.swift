//
//  File.swift
//  
//
//  Created by Sasha on 07/03/2021.
//

import Foundation

internal protocol ResurseSetupable {
    
    var url: String { get }
    var httpMethod: HTTPMethod  { get }
    var parameters: Parameters?  { get }
    var httpHeaders: [String:String]  { get }
    var parametersType: ParametersType  { get }
    
    func setupRequest() -> Result<URLRequest, NetworkError>
    
}
