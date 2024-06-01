//
//  Token.swift
//  
//
//  
//

import Foundation

public struct Token: CustomStringConvertible {
    let lexeme: String
    let kind: Kind
    let line: Int
    
    enum Kind: CustomStringConvertible {
        case keyword
        case instruction
        case numericLiteral
        case charLiteral
        case identifier
        case punctuation
        case `operator`
        case eof
        
        var description: String {
            switch self {
            case .keyword: return "keyword"
            case .instruction: return "instruction"
            case .charLiteral: return "char literal"
            case .numericLiteral: return "numeric literal"
            case .identifier: return "identifier"
            case .punctuation: return "punctuation"
            case .operator: return "operator"
            case .eof: return "eof"
            }
        }
    }
    
    public var description: String {
        "Line \(line): \(lexeme) - \(kind)\n"
    }
}
