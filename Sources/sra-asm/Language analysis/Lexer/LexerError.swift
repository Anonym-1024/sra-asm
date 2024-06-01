//
//
//  
//
//
//

import Foundation

struct LexerError: CompilerError {
    public init(line: Int, kind: LexerError.Kind) {
        self.line = line
        self.kind = kind
    }
    
    var line: Int
    
    var errorDescription: String {
        switch kind {
        case .invalidCharacter:
            return "Invalid character found"
        case .invalidCharLiteral:
            return "Invalid character literal"
        case .invalidNumericLiteral:
            return "Invalid numeric literal"
        }
    }
    
    var kind: Kind
    
    enum Kind {
        case invalidCharacter
        case invalidCharLiteral
        case invalidNumericLiteral
    }
}
