//
//  
//  
//
//
//

import Foundation

public class Parser {
    public init(fileType: File.FileType) {
        self.tokens = []
        self.pos = 0
        self.fileType = fileType
        self.errors = []
        self.parsing = []
    }
    
    
    public var tokens: [Token]
    var pos: Int
    var fileType: File.FileType
    public var errors: [ParserError]
    
    var parsing: [AST.Node.NonTerminal]
    var line: Int {
        if pos < tokens.count {
            return tokens[pos].line
        }
        return 0
    }
    
    
    // Helpers
    
    /// Pop terminal when kind is matched while ignoring newlines
    func popTerminal(kind: Token.Kind) -> Token? {
        var _pos = pos
        while _pos < tokens.count, tokens[_pos].lexeme == "\n" {
            _pos += 1
        }
        if _pos < tokens.count {
            let token = tokens[_pos]
            if token.kind == kind {
                pos = _pos + 1
                return token
            }
        }
        return nil
    }
    
    
    /// Pop terminal when lexeme is matched while ignoring newlines
    func popTerminal(_ lexeme: String) -> Token? {
        var _pos = pos
        while _pos < tokens.count, tokens[_pos].lexeme == "\n" {
            _pos += 1
        }
        if _pos < tokens.count {
            let token = tokens[_pos]
            if token.lexeme == lexeme {
                pos = _pos + 1
                return token
            }
        }
        return nil
    }
    
    
    /// Pop newline token
    func popNewLine() -> Bool{
        if pos < tokens.count, tokens[pos].lexeme == "\n" {
            pos += 1
            return true
        }
        return false
    }
    
    
    /// Check if lookahead matches a kind
    func lookAhead(offset: Int = 0, _ kind: Token.Kind) -> Bool {
        var _pos = pos
        for _ in 0..<(offset + 1) {
            while _pos < tokens.count, tokens[_pos].lexeme == "\n" {
                _pos += 1
            }
            _pos += 1
        }
        _pos -= 1
        if _pos + offset < tokens.count {
            let token = tokens[_pos]
            return token.kind == kind
        }
        return false
    }
    
    
    /// Check if lookahead matches a lexeme
    func lookAhead(offset: Int = 0, _ lexeme: String) -> Bool {
        var _pos = pos
        for _ in 0..<(offset + 1) {
            while _pos < tokens.count, tokens[_pos].lexeme == "\n" {
                _pos += 1
            }
            _pos += 1
        }
        _pos -= 1
            
        if _pos + offset < tokens.count {
            let token = tokens[_pos]
            return token.lexeme == lexeme
        }
        return false
    }
    
    
    func error(_ kind: ParserError.Kind) -> ParserError {
        let err =  ParserError(line: line, kind: kind, parsing: parsing.last!)
        errors.append(err)
        return err
    } 
    
    
    
    
    
    
    
    
    
    // ------ Parsing ASM -------
    
    
    public func parseAsm() throws -> AST.Node {
        parsing.append(.asm)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let sections = try? parseSections() {
            children.append(sections)
        }
        // errors.removeAll()
        
        guard let eof = popTerminal(kind: .eof) else { throw error(.expectedTerminalOfKind(.eof)) }
        children.append(.terminal(eof))
        
        
        return .nonTerminal(.asm, children: children)
    }
    
    
    func parseSections() throws -> AST.Node {
        parsing.append(.sections)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        let section = try parseSection()
        children.append(section)
        
        if popNewLine() {
            if let sections = try? parseSections() {
                children.append(sections)
            }
        }
        
        
        return .nonTerminal(.sections, children: children)
    }
    
    
    func parseSection() throws -> AST.Node {
        parsing.append(.section)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
    
        if lookAhead("exec") {
            let exec = try parseExec()
            children.append(exec)
        } else if lookAhead("data") {
            let data = try parseData()
            children.append(data)
        } else {
            throw error(.expectedNonTerminal(.section))
        }
        
        
        return .nonTerminal(.section, children: children)
    }
    
    
    func parseExec() throws -> AST.Node {
        parsing.append(.exec)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let exec = popTerminal("exec") else { throw error(.expectedTerminal("exec")) }
        children.append(.terminal(exec))
        
        guard let braceL = popTerminal("{") else { throw error(.expectedTerminal("{")) }
        children.append(.terminal(braceL))
        
        if let functions = try? parseFunctions() {
            children.append(functions)
        }
        
        guard let braceR = popTerminal("}") else { throw error(.expectedTerminal("}")) }
        children.append(.terminal(braceR))
        
        
        return .nonTerminal(.exec, children: children)
    }
    
    
    func parseFunctions() throws -> AST.Node {
        parsing.append(.functions)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        let function = try parseFunction()
        children.append(function)
        
        if popNewLine() {
            if let functions = try? parseFunctions() {
                children.append(functions)
            }
        }
        
        
        return .nonTerminal(.functions, children: children)
    }
    
    
    func parseFunction() throws -> AST.Node {
        parsing.append(.function)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let main = popTerminal("main") {
            children.append(.terminal(main))
            
            guard let braceL = popTerminal("{") else { throw error(.expectedTerminal("{")) }
            children.append(.terminal(braceL))
            
            if let instructions = try? parseInstructions() {
                children.append(instructions)
            }
            
            guard let braceR = popTerminal("}") else { throw error(.expectedTerminal("}")) }
            children.append(.terminal(braceR))
            
        } else {
            guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
            children.append(.terminal(identifier))
            
            while lookAhead("(") {
                while !lookAhead(")") {
                    if pos < tokens.count {
                        pos += 1
                    } else {
                        throw error(.expectedTerminal(")"))
                    }
                }
                pos += 1
            }
            
            guard let braceL = popTerminal("{") else { throw error(.expectedTerminal("{")) }
            children.append(.terminal(braceL))
            
            if let instructions = try? parseInstructions() {
                children.append(instructions)
            }
            
            guard let braceR = popTerminal("}") else { throw error(.expectedTerminal("}")) }
            children.append(.terminal(braceR))
        }
        
        
        
        
        return .nonTerminal(.function, children: children)
    }
    
    
    /*func parseFuncArgs() throws -> AST.Node {
        parsing.append(.funcArgs)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        
        
        
        return .nonTerminal(.funcArgs, children: children)
    }
    
    
    func parseFuncArg() throws -> AST.Node {
        parsing.append(.funcArg)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        
        
        return .nonTerminal(.funcArg, children: children)
    }*/
    
    
    func parseLocation() throws -> AST.Node {
        parsing.append(.location)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
        children.append(.terminal(identifier))
        
        if let dot = try? popTerminal(".") {
            
            let location = try parseLocation()
            children.append(location)
        }
        
        return .nonTerminal(.location, children: children)
    }
    
    
    func parseInstructions() throws -> AST.Node {
        parsing.append(.instructions)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        let instruction = try parseInstruction()
        children.append(instruction)
        
        if parseBreak() {
            
            if let instructions = try? parseInstructions() {
                children.append(instructions)
            }
        }
        
        return .nonTerminal(.instructions, children: children)
    }
    
    
    func parseInstruction() throws -> AST.Node {
        parsing.append(.instruction)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if let label = try? parseLabel() {
            children.append(label)
        }
        
        
        
        guard let instruction = popTerminal(kind: .instruction) else { throw error(.invalidInstruction) }
        children.append(.terminal(instruction))
        
        if let args = try? parseArgs() {
            children.append(args)
        }
        
        return .nonTerminal(.instruction, children: children)
    }
    
    
    func parseBreak() -> Bool {
        if popNewLine() {
            return true
        }
        return popTerminal(";") != nil || lookAhead("}")
    }
    
    
    func parseLabel() throws -> AST.Node {
        parsing.append(.label)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
        children.append(.terminal(identifier))
        
        guard let colon = popTerminal(":") else { throw error(.expectedTerminal(":")) }
        children.append(.terminal(colon))
        
        popNewLine()
        
        
        return .nonTerminal(.label, children: children)
    }
    
    
    func parseArgs() throws -> AST.Node {
        parsing.append(.args)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        let arg = try parseArg()
        children.append(arg)
        
        if let dot = popTerminal(",") {
            
            let args = try parseArgs()
            children.append(args)
        }
        
        return .nonTerminal(.args, children: children)
    }
    
    
    func parseArg() throws -> AST.Node {
        parsing.append(.arg)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if lookAhead(.identifier) {
            let location = try parseLocation()
            children.append(location)
        } else if lookAhead("#") {
            let immediate = try parseImmediate()
            children.append(immediate)
        } else {
            throw error(.expectedNonTerminal(.arg))
        }
        
        
        return .nonTerminal(.arg, children: children)
    }
    
    
    func parseImmediate() throws -> AST.Node {
        parsing.append(.immediate)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let numberSign = popTerminal("#") else { throw error(.expectedTerminal("#")) }
        children.append(.terminal(numberSign))
                                            
        guard let numericLiteral = popTerminal(kind: .numericLiteral) else { throw error(.expectedTerminalOfKind(.numericLiteral)) }
        children.append(.terminal(numericLiteral))
        
        if let bracketL = popTerminal("[") {
            
            guard let numericLiteral_ = popTerminal(kind: .numericLiteral) else { throw error(.expectedTerminalOfKind(.numericLiteral)) }
            children.append(.terminal(numericLiteral_))
            
            guard let bracketR = popTerminal("]") else { throw error(.expectedTerminal("]")) }
        }
        
        return .nonTerminal(.immediate, children: children)
    }
    
    
    func parseData() throws -> AST.Node {
        parsing.append(.data)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        guard let data = popTerminal("data") else { throw error(.expectedTerminal("data")) }
        children.append(.terminal(data))
        
        guard let braceL = popTerminal("{") else { throw error(.expectedTerminal("{")) }
        children.append(.terminal(braceL))
        
        if let dataBlocks = try? parseDataBlocks() {
            children.append(dataBlocks)
        }
        
        guard let braceR = popTerminal("}") else { throw error(.expectedTerminal("}")) }
        children.append(.terminal(braceR))
        
        return .nonTerminal(.data, children: children)
    }
    
    
    func parseDataBlocks() throws -> AST.Node {
        parsing.append(.dataBlocks)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        let dataBlock = try parseDataBlock()
        children.append(dataBlock)
        
        
            
            if let dataBlocks = try? parseDataBlocks() {
                children.append(dataBlocks)
            }
        
        
        return .nonTerminal(.dataBlocks, children: children)
    }
    
    
    func parseDataBlock() throws -> AST.Node {
        parsing.append(.dataBlock)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if lookAhead(offset: 1, "{") {
            guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
            children.append(.terminal(identifier))
            
            guard let braceL = popTerminal("{") else { throw error(.expectedTerminal("{")) }
            
            if let variables = try? parseVariables() {
                children.append(variables)
            }
            
            
            
            guard let braceR = popTerminal("}") else { throw error(.expectedTerminal("}")) }
            parseBreak()
        } else {
            let variables = try parseVariables()
            children.append(variables)
        }
        
        return .nonTerminal(.dataBlock, children: children)
    }
    
    
    func parseVariables() throws -> AST.Node {
        
        parsing.append(.variables)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        let variable = try parseVariable()
        children.append(variable)
        
        if parseBreak() {
            if let variables = try? parseVariables() {
                children.append(variables)
            }
            
        }
        
        return .nonTerminal(.variables, children: children)
    }
    
    
    func parseVariable() throws -> AST.Node {
        parsing.append(.variable)
        defer {
            parsing.removeLast()
        }
        
        var children = [AST.Node]()
        
        if lookAhead(offset: 1, "{") {
            throw error(.notVariable)
        }
        
        guard let identifier = popTerminal(kind: .identifier) else { throw error(.expectedTerminalOfKind(.identifier)) }
        children.append(.terminal(identifier))
        
        
        
        if let equals = popTerminal("=") {
            children.append(.terminal(equals))
            if let numericLiteral = popTerminal(kind: .numericLiteral) {
                children.append(.terminal(numericLiteral))
            } else {
                guard let charLiteral = popTerminal(kind: .charLiteral) else { throw error(.expectedTerminalOfKind(.charLiteral))}
                children.append(.terminal(charLiteral))
            }
        }
        
        return .nonTerminal(.variable, children: children)
    }
    
    
}
