//
// ParserError.swift
//


import Foundation


public struct ParserError: CompilerError {
    init(line: Int, kind: ParserError.Kind, parsing: AST.Node.NonTerminal) {
        self.line = line
        self.kind = kind
        self.parsing = parsing
    }
    
    let line: Int
    let parsing: AST.Node.NonTerminal
    
    var errorDescription: String {
        switch kind {
        case .expectedTerminalOfKind(let kind):
            return "Expected terminal of kind \(kind); Found while parsing: \(parsing)"
        case .expectedTerminal(let terminal):
            return "Expected terminal \(terminal); Found while parsing: \(parsing)"
        case .expectedNonTerminal(let nonTerminal):
            return "Expected nonterminal \(nonTerminal); Found while parsing: \(parsing)"
        case .outOfRange:
            return "Out of range"
        case .invalidInstruction:
            return "Unknown instruction"
        case .notVariable:
            return "Not a variable"
        
        }
    }
    
    var kind: Kind
    
    enum Kind {
        case expectedTerminalOfKind(Token.Kind)
        case expectedTerminal(String)
        case expectedNonTerminal(AST.Node.NonTerminal)
        case outOfRange
        case invalidInstruction
        case notVariable
    }
}
