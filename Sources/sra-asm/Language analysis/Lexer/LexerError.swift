//
// LexerError.swift
//


import Foundation

struct LexerError: CompilerError {
    init(line: Int, kind: LexerError.Kind) {
        self.line = line
        self.kind = kind
    }
    
    let line: Int
    
    var errorDescription: String {
        switch kind {
        case .invalidCharacter:
            return "Invalid character found"
        case .invalidCharLiteral:
            return "Invalid character literal"
        case .invalidNumericLiteral:
            return "Invalid numeric literal"
        case .invalidUrl:
            return "Invalid URL"
        }
    }
    
    let kind: Kind
    
    enum Kind {
        case invalidCharacter
        case invalidCharLiteral
        case invalidNumericLiteral
        case invalidUrl
    }
}
