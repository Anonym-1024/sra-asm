//
//  SemanticError.swift
//  


import Foundation


struct SemanticError: CompilerError {
    
    let kind: Kind
    let line: Int
    
    
    var errorDescription: String {
        switch kind {
        case .missingEntryPoint:
            return "Missing progrm entry point"
        case .missingExec:
            return "Missing executable section"
        case .duplicateSymbol(let symbol):
            return "Duplicate of symbol \"\(symbol)\" found"
        }
    }
    
    enum Kind {
        case missingEntryPoint
        case missingExec
        case duplicateSymbol(String)
    }
    
}
