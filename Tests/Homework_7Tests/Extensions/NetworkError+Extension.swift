//
//  NetworkError+Extension.swift
//  
//
//  Created by Sasha on 05/03/2021.
//

import Foundation
@testable import Homework_7

extension NetworkError: Equatable {
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        return "\(lhs)" == "\(rhs)"
    }
    
}
