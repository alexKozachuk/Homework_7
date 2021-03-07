//
//  File 3.swift
//  
//
//  Created by Sasha on 07/03/2021.
//

import Foundation

public protocol ResurseResponsable {
    
    func response(completion: @escaping (Result<Data, NetworkError>) -> Void)
    func responseDecodable<T: Decodable>(of type: T.Type,
                                         completion: @escaping (Result<T, NetworkError>) -> Void)
    func responseJSON(completion: @escaping (Result<Any, NetworkError>) -> Void)
    func responseString(completion: @escaping (Result<String, NetworkError>) -> Void)
    
}
