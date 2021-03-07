//
//  File 2.swift
//  
//
//  Created by Sasha on 07/03/2021.
//

import Foundation

public protocol ResurseValidated {
    
    func validate<S: Sequence>(statusCode: S) -> Self where S.Iterator.Element == Int
    func validate(contentType: String) -> DataTask
    func validate() -> Self
    
}
