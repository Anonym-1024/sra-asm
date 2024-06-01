//
//
//
//
//
//

import Foundation


struct ParserError: CompilerError {
    public init(line: Int, kind: ParserError.Kind) {
        self.line = line
        self.kind = kind
    }
    
    var line: Int
    
    var errorDescription: String {
        switch kind {
        case .expectedTerminalOfKind(let kind):
            return "Excepted terminal of kind \(kind)"
        case .expectedTerminal(let terminal):
            return "Excepted terminal \(terminal)"
        case .invalidFuncArguments:
            return "Invalid func arguments"
        case .outOfRange:
            return "Out of range"
        }
    }
    
    var kind: Kind
    
    enum Kind {
        case expectedTerminalOfKind(Token.Kind)
        case expectedTerminal(String)
        case invalidFuncArguments
        case outOfRange
    }
}
