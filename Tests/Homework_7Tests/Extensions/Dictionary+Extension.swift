//
//  Dictionary+Extension.swift
//  
//
//  Created by Sasha on 06/03/2021.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    
    public static func == (lhs: Dictionary<Key, Value>, rhs: Dictionary<Key, Value>) -> Bool {
        let lhsSorted = lhs.sorted (by: { $0.key > $1.key})
        let rhsSorted = rhs.sorted (by: { $0.key > $1.key})
        return "\(lhsSorted)" == "\(rhsSorted)"
    }
    
}
