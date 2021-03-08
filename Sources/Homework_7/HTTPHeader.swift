//
//  HTTPHeader.swift
//  
//
//  Created by Sasha on 05/03/2021.
//

import Foundation

public struct HTTPHeader: Hashable {
    
    var name: String
    var value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
}

extension Array where Element == HTTPHeader {
    
    func getDict() -> [String: String] {
        var dict: [String: String] = [:]
        
        self.forEach {
            dict[$0.name] = $0.value
        }
        
        return dict
    }
    
}
