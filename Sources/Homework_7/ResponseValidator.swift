//
//  ResponseValidator.swift
//  
//
//  Created by Sasha on 07/03/2021.
//

import Foundation


internal final class ResponseValidator<S: Sequence> where S.Iterator.Element == Int {
    
    private var acceptableStatusCodes: S
    
    init(_ statusCode: S) {
        self.acceptableStatusCodes = statusCode
    }
    
    func validate(response: HTTPURLResponse) -> Bool {
        acceptableStatusCodes.contains(response.statusCode)
    }
    
}
