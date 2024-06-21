//
//  File.swift
//  
//
//  Created by Václav Koukola on 21.06.2024.
//

import Foundation

public struct CompilerContext {
    public init(libraries: [Library], product: Header.Product) {
        self.libraries = libraries
        self.product = product
    }
    
    let libraries: [Library]
    let product: Header.Product
}
