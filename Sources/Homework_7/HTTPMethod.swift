//
//  HTTPMethod.swift
//  
//
//  Created by Sasha on 04/03/2021.
//

import Foundation

public enum HTTPMethod: String {
    case get, post, put, delete
    
    public var title: String {
        self.rawValue.uppercased()
    }
    
}
